MERGE `claims-etl-learning.claims_staging.stg_claims` AS target
USING (
    SELECT
        claim_id,
        patient_id,
        claim_amount,
        UPPER(TRIM(claim_status)) AS claim_status,
        claim_date,
        updated_at
    FROM `claims-etl-learning.claims_raw.claims_incoming`
    WHERE claim_id IS NOT NULL
      AND patient_id IS NOT NULL
      AND claim_amount IS NOT NULL
      AND claim_amount >= 0
      AND UPPER(TRIM(claim_status))
          IN ('PAID', 'PENDING', 'DENIED')
      AND claim_date IS NOT NULL
      AND updated_at IS NOT NULL
) AS source
ON target.claim_id = source.claim_id

WHEN MATCHED
     AND source.updated_at > target.updated_at
THEN UPDATE SET
    patient_id = source.patient_id,
    claim_amount = source.claim_amount,
    claim_status = source.claim_status,
    claim_date = source.claim_date,
    updated_at = source.updated_at

WHEN NOT MATCHED
THEN INSERT (
    claim_id,
    patient_id,
    claim_amount,
    claim_status,
    claim_date,
    updated_at
)
VALUES (
    source.claim_id,
    source.patient_id,
    source.claim_amount,
    source.claim_status,
    source.claim_date,
    source.updated_at
);