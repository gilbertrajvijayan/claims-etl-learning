import os
import uuid
from pathlib import Path

import functions_framework
from google.cloud import bigquery


PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "claims-etl-learning")
LOCATION = "us-central1"
INCOMING_TABLE = f"{PROJECT_ID}.claims_raw.claims_incoming"
SQL_FOLDER = Path(__file__).parent / "sql"


def read_sql(file_name):
    """Reads a SQL file packaged with the Cloud Run function."""
    sql_path = SQL_FOLDER / file_name
    return sql_path.read_text(encoding="utf-8")


def run_sql(client, file_name, parameters=None):
    """Runs one packaged SQL file in BigQuery."""
    query = read_sql(file_name)

    job_config = bigquery.QueryJobConfig(
        query_parameters=parameters or []
    )

    print(f"Running SQL: {file_name}")

    client.query(
        query,
        job_config=job_config,
        location=LOCATION,
    ).result()


def load_incoming_file(client, bucket_name, file_name):
    """Loads the incoming Cloud Storage CSV into the raw BigQuery table."""
    source_uri = f"gs://{bucket_name}/{file_name}"

    schema = [
        bigquery.SchemaField("claim_id", "STRING"),
        bigquery.SchemaField("patient_id", "STRING"),
        bigquery.SchemaField("claim_amount", "INTEGER"),
        bigquery.SchemaField("claim_status", "STRING"),
        bigquery.SchemaField("claim_date", "DATE"),
        bigquery.SchemaField("updated_at", "TIMESTAMP"),
    ]

    load_config = bigquery.LoadJobConfig(
        schema=schema,
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    print(f"Loading {source_uri} into {INCOMING_TABLE}")

    client.load_table_from_uri(
        source_uri,
        INCOMING_TABLE,
        job_config=load_config,
        location=LOCATION,
    ).result()


@functions_framework.cloud_event
def process_claims_file(cloud_event):
    """Runs the claims pipeline when an incoming CSV is uploaded."""

    event_data = cloud_event.data
    bucket_name = event_data["bucket"]
    file_name = event_data["name"]

    print(f"Received file: gs://{bucket_name}/{file_name}")

    if not file_name.startswith("raw/claims_batch_"):
        print("File ignored because it is not an incoming claims batch.")
        return

    if not file_name.lower().endswith(".csv"):
        print("File ignored because it is not a CSV file.")
        return

    print(f"Accepted claims file: {file_name}")

    run_id = str(uuid.uuid4())
    batch_file = Path(file_name).name
    client = bigquery.Client(project=PROJECT_ID)
    current_step = "AUDIT_START"

    run_id_parameter = bigquery.ScalarQueryParameter(
        "run_id", "STRING", run_id
    )

    try:
        run_sql(
            client,
            "audit_pipeline_start.sql",
            [
                run_id_parameter,
                bigquery.ScalarQueryParameter(
                    "batch_file", "STRING", batch_file
                ),
            ],
        )

        current_step = "RAW_TABLE_LOAD"
        load_incoming_file(client, bucket_name, file_name)

        current_step = "VALID_CLAIMS_MERGE"
        run_sql(client, "merge_incoming_claims.sql")

        current_step = "REJECTED_CLAIMS_MERGE"
        run_sql(client, "merge_incoming_rejected_claims.sql")

        current_step = "MART_MERGE"
        run_sql(client, "merge_incoming_fct_claims.sql")

        current_step = "RECONCILIATION"
        run_sql(client, "incremental_reconciliation.sql")

        current_step = "DATA_QUALITY_CHECKS"
        run_sql(
            client,
            "run_data_quality_checks.sql",
            [run_id_parameter],
        )

        current_step = "AUDIT_SUCCESS"
        run_sql(
            client,
            "audit_pipeline_success.sql",
            [run_id_parameter],
        )

        print(
            f"Pipeline completed successfully. "
            f"Run ID: {run_id}, file: {batch_file}"
        )

    except Exception as error:
        print(
            f"Pipeline failed during {current_step}: {error}"
        )

        try:
            run_sql(
                client,
                "audit_pipeline_failed.sql",
                [
                    run_id_parameter,
                    bigquery.ScalarQueryParameter(
                        "error_step", "STRING", current_step
                    ),
                    bigquery.ScalarQueryParameter(
                        "error_message",
                        "STRING",
                        str(error)[:1000],
                    ),
                ],
            )
        except Exception as audit_error:
            print(f"Failure audit update also failed: {audit_error}")

        raise