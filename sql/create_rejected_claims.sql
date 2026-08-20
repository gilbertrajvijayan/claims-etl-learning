-- Create a table containing invalid and older duplicate records

CREATE OR REPLACE TABLE
  `claims-etl-learning.claims_staging.rejected_claims` AS

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
    claim_status,
    claim_date,
    updated_at,
    CASE
        WHEN row_num > 1
            THEN 'OLDER_DUPLICATE_RECORD'
        WHEN claim_id IS NULL
            THEN 'MISSING_CLAIM_ID'
        WHEN patient_id IS NULL
            THEN 'MISSING_PATIENT_ID'
        WHEN claim_amount IS NULL
            THEN 'MISSING_CLAIM_AMOUNT'
        WHEN claim_amount < 0
            THEN 'NEGATIVE_CLAIM_AMOUNT'
        WHEN UPPER(TRIM(claim_status))
             NOT IN ('PAID', 'PENDING', 'DENIED')
            THEN 'INVALID_CLAIM_STATUS'
    END AS error_reason
FROM ranked_claims
WHERE row_num > 1
   OR claim_id IS NULL
   OR patient_id IS NULL
   OR claim_amount IS NULL
   OR claim_amount < 0
   OR UPPER(TRIM(claim_status))
      NOT IN ('PAID', 'PENDING', 'DENIED');