UPDATE `claims-etl-learning.claims_control.pipeline_audit`
SET
  end_time = CURRENT_TIMESTAMP(),
  run_status = 'SUCCESS',

  raw_record_count = (
    SELECT COUNT(*)
    FROM `claims-etl-learning.claims_raw.claims_incoming`
  ),

  valid_record_count = (
    SELECT COUNT(*)
    FROM `claims-etl-learning.claims_raw.claims_incoming`
    WHERE claim_id IS NOT NULL
      AND patient_id IS NOT NULL
      AND claim_amount IS NOT NULL
      AND claim_amount >= 0
      AND UPPER(TRIM(claim_status)) IN ('PAID', 'PENDING', 'DENIED')
      AND claim_date IS NOT NULL
      AND updated_at IS NOT NULL
  ),

  rejected_record_count = (
    SELECT COUNT(*)
    FROM `claims-etl-learning.claims_raw.claims_incoming`
    WHERE claim_id IS NULL
       OR patient_id IS NULL
       OR claim_amount IS NULL
       OR claim_amount < 0
       OR UPPER(TRIM(claim_status)) NOT IN ('PAID', 'PENDING', 'DENIED')
       OR claim_date IS NULL
       OR updated_at IS NULL
  ),

  mart_record_count = (
    SELECT COUNT(*)
    FROM `claims-etl-learning.claims_mart.fct_claims`
  )

WHERE run_id = @run_id;