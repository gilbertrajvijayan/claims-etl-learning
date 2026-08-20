CREATE TABLE IF NOT EXISTS
  `claims-etl-learning.claims_control.data_quality_results`
(
  run_id STRING NOT NULL,
  test_name STRING NOT NULL,
  test_status STRING NOT NULL,
  failed_record_count INT64 NOT NULL,
  check_time TIMESTAMP NOT NULL,
  test_description STRING
)
PARTITION BY DATE(check_time)
CLUSTER BY test_status, test_name;