SELECT
  run_status,
  COUNT(*) AS total_runs,
  ROUND(AVG(duration_seconds), 2) AS avg_duration_seconds
FROM `claims-etl-learning.claims_control.vw_pipeline_monitoring`
GROUP BY run_status
ORDER BY total_runs DESC;