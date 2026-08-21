MERGE `claims-etl-learning.claims_staging.rejected_claims` AS target
USING (
    SELECT
        claim_id,
        patient_id,
        claim_amount,
        claim_status,
        claim_date,
        updated_at,
        CASE
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
    FROM `claims-etl-learning.claims_raw.claims_incoming`
    WHERE claim_id IS NULL
       OR patient_id IS NULL
       OR claim_amount IS NULL
       OR claim_amount < 0
       OR UPPER(TRIM(claim_status))
          NOT IN ('PAID', 'PENDING', 'DENIED')
       OR claim_date IS NULL
       OR updated_at IS NULL
) AS source
ON target.claim_id = source.claim_id
AND target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
INSERT (
    claim_id,
    patient_id,
    claim_amount,
    claim_status,
    claim_date,
    updated_at,
    error_reason
)
VALUES (
    source.claim_id,
    source.patient_id,
    source.claim_amount,
    source.claim_status,
    source.claim_date,
    source.updated_at,
    source.error_reason
);