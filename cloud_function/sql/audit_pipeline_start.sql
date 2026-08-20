INSERT INTO `claims-etl-learning.claims_control.pipeline_audit`
(
  run_id,
  batch_file,
  start_time,
  run_status
)
VALUES
(
  @run_id,
  @batch_file,
  CURRENT_TIMESTAMP(),
  'STARTED'
);