CREATE OR REPLACE VIEW
  `claims-etl-learning.claims_control.vw_pipeline_monitoring`
AS
SELECT
  run_id,
  batch_file,
  run_status,
  start_time,
  end_time,
  TIMESTAMP_DIFF(end_time, start_time, SECOND) AS duration_seconds,
  raw_record_count,
  valid_record_count,
  rejected_record_count,
  mart_record_count,
  SAFE_DIVIDE(valid_record_count, raw_record_count) * 100
    AS valid_percentage,
  error_step,
  error_message
FROM `claims-etl-learning.claims_control.pipeline_audit`;