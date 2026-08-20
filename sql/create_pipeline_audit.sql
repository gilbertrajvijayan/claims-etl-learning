CREATE TABLE IF NOT EXISTS
  `claims-etl-learning.claims_control.pipeline_audit`
(
  run_id STRING NOT NULL,
  batch_file STRING NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  run_status STRING NOT NULL,
  raw_record_count INT64,
  valid_record_count INT64,
  rejected_record_count INT64,
  mart_record_count INT64,
  error_step STRING,
  error_message STRING
)
PARTITION BY DATE(start_time)
CLUSTER BY run_status, batch_file;