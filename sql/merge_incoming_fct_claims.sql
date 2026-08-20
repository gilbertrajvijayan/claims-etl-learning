MERGE `claims-etl-learning.claims_mart.fct_claims` AS target
USING (
    SELECT
        c.claim_id,
        c.patient_id,
        p.patient_name,
        p.state,
        c.claim_amount,
        c.claim_status,
        c.claim_date,
        c.updated_at
    FROM `claims-etl-learning.claims_staging.stg_claims` AS c
    INNER JOIN `claims-etl-learning.claims_staging.stg_patients` AS p
        ON c.patient_id = p.patient_id
    WHERE c.claim_id IN (
        SELECT claim_id
        FROM `claims-etl-learning.claims_raw.claims_incoming`
    )
) AS source
ON target.claim_id = source.claim_id

WHEN MATCHED
     AND source.updated_at > target.updated_at
THEN UPDATE SET
    patient_id = source.patient_id,
    patient_name = source.patient_name,
    state = source.state,
    claim_amount = source.claim_amount,
    claim_status = source.claim_status,
    claim_date = source.claim_date,
    updated_at = source.updated_at

WHEN NOT MATCHED
THEN INSERT (
    claim_id,
    patient_id,
    patient_name,
    state,
    claim_amount,
    claim_status,
    claim_date,
    updated_at
)
VALUES (
    source.claim_id,
    source.patient_id,
    source.patient_name,
    source.state,
    source.claim_amount,
    source.claim_status,
    source.claim_date,
    source.updated_at
);