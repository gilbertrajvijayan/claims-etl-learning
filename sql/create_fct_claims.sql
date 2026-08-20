CREATE OR REPLACE TABLE
  `claims-etl-learning.claims_mart.fct_claims`
PARTITION BY claim_date
CLUSTER BY state, claim_status AS

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
    ON c.patient_id = p.patient_id;