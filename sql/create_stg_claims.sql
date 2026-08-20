-- Create the cleaned and deduplicated staging table

CREATE OR REPLACE TABLE
  `claims-etl-learning.claims_staging.stg_claims` AS

WITH ranked_claims AS (
    SELECT
        claim_id,
        patient_id,
        claim_amount,
        claim_status,
        claim_date,
        updated_at,
        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY updated_at DESC
        ) AS row_num
    FROM `claims-etl-learning.claims_raw.claims`
)

SELECT
    claim_id,
    patient_id,
    claim_amount,
    UPPER(TRIM(claim_status)) AS claim_status,
    claim_date,
    updated_at
FROM ranked_claims
WHERE row_num = 1
  AND claim_id IS NOT NULL
  AND patient_id IS NOT NULL
  AND claim_amount IS NOT NULL
  AND claim_amount >= 0
  AND UPPER(TRIM(claim_status))
      IN ('PAID', 'PENDING', 'DENIED');