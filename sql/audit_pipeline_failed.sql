UPDATE `claims-etl-learning.claims_control.pipeline_audit`
SET
  end_time = CURRENT_TIMESTAMP(),
  run_status = 'FAILED',
  error_step = @error_step,
  error_message = @error_message
WHERE run_id = @run_id;