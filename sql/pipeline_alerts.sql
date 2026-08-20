SELECT
  run_id,
  batch_file,
  run_status,
  start_time,
  end_time,
  duration_seconds,
  error_step,
  error_message
FROM `claims-etl-learning.claims_control.vw_pipeline_monitoring`
WHERE
  (
    run_status = 'FAILED'
    AND start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
  )
  OR
  (
    run_status = 'STARTED'
    AND start_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 MINUTE)
  )
ORDER BY start_time DESC;