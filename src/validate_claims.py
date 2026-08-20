from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_FILE = PROJECT_ROOT / "data" / "raw" / "claims.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed"

VALID_STATUSES = {"PAID", "PENDING", "DENIED"}


def find_error(row):
    errors = []

    if pd.isna(row["claim_id"]) or not str(row["claim_id"]).strip():
        errors.append("MISSING_CLAIM_ID")

    if pd.isna(row["patient_id"]) or not str(row["patient_id"]).strip():
        errors.append("MISSING_PATIENT_ID")

    if pd.isna(row["claim_amount"]):
        errors.append("MISSING_CLAIM_AMOUNT")
    elif row["claim_amount"] < 0:
        errors.append("NEGATIVE_CLAIM_AMOUNT")

    if row["claim_status"] not in VALID_STATUSES:
        errors.append("INVALID_CLAIM_STATUS")

    if pd.isna(row["claim_date"]):
        errors.append("INVALID_CLAIM_DATE")

    if pd.isna(row["updated_at"]):
        errors.append("INVALID_UPDATED_AT")

    return "|".join(errors) if errors else None


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    claims = pd.read_csv(INPUT_FILE)

    input_count = len(claims)

    claims["claim_status"] = (
        claims["claim_status"]
        .astype("string")
        .str.strip()
        .str.upper()
    )

    claims["patient_id"] = claims["patient_id"].astype("string").str.strip()

    claims["claim_amount"] = pd.to_numeric(
        claims["claim_amount"],
        errors="coerce",
    )

    claims["claim_date"] = pd.to_datetime(
        claims["claim_date"],
        errors="coerce",
    )

    claims["updated_at"] = pd.to_datetime(
        claims["updated_at"],
        errors="coerce",
    )

    claims = claims.sort_values(
        by="updated_at",
        ascending=False,
    )

    duplicate_rows = claims[
        claims.duplicated(subset=["claim_id"], keep="first")
    ].copy()

    duplicate_rows["error_reason"] = "OLDER_DUPLICATE_RECORD"

    latest_claims = claims[
        ~claims.duplicated(subset=["claim_id"], keep="first")
    ].copy()

    latest_claims["error_reason"] = latest_claims.apply(
        find_error,
        axis=1,
    )

    valid_claims = latest_claims[
        latest_claims["error_reason"].isna()
    ].copy()

    rejected_claims = latest_claims[
        latest_claims["error_reason"].notna()
    ].copy()

    rejected_claims = pd.concat(
        [rejected_claims, duplicate_rows],
        ignore_index=True,
    )

    valid_claims = valid_claims.drop(columns=["error_reason"])

    valid_claims.to_csv(
        OUTPUT_DIR / "valid_claims.csv",
        index=False,
    )

    rejected_claims.to_csv(
        OUTPUT_DIR / "rejected_claims.csv",
        index=False,
    )

    print(f"Input records: {input_count}")
    print(f"Valid records: {len(valid_claims)}")
    print(f"Rejected records: {len(rejected_claims)}")
    print("Pipeline completed successfully.")


if __name__ == "__main__":
    main()