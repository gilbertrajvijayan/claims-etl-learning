CREATE OR REPLACE TABLE
  `claims-etl-learning.claims_staging.rejected_patients` AS

SELECT
    patient_id,
    patient_name,
    state,
    CASE
        WHEN patient_id IS NULL OR TRIM(patient_id) = ''
            THEN 'MISSING_PATIENT_ID'
        WHEN patient_name IS NULL OR TRIM(patient_name) = ''
            THEN 'MISSING_PATIENT_NAME'
        WHEN state IS NULL OR TRIM(state) = ''
            THEN 'MISSING_STATE'
        WHEN NOT REGEXP_CONTAINS(
            UPPER(TRIM(state)),
            r'^[A-Z]{2}$'
        )
            THEN 'INVALID_STATE'
    END AS error_reason
FROM `claims-etl-learning.claims_raw.patients`
WHERE patient_id IS NULL
   OR TRIM(patient_id) = ''
   OR patient_name IS NULL
   OR TRIM(patient_name) = ''
   OR state IS NULL
   OR TRIM(state) = ''
   OR NOT REGEXP_CONTAINS(
       UPPER(TRIM(state)),
       r'^[A-Z]{2}$'
   );