CREATE OR REPLACE TABLE
  `claims-etl-learning.claims_staging.stg_patients` AS

SELECT DISTINCT
    TRIM(patient_id) AS patient_id,
    TRIM(patient_name) AS patient_name,
    UPPER(TRIM(state)) AS state
FROM `claims-etl-learning.claims_raw.patients`
WHERE patient_id IS NOT NULL
  AND TRIM(patient_id) != ''
  AND patient_name IS NOT NULL
  AND TRIM(patient_name) != ''
  AND state IS NOT NULL
  AND REGEXP_CONTAINS(
      UPPER(TRIM(state)),
      r'^[A-Z]{2}$'
  );