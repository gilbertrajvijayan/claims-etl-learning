INSERT INTO `claims-etl-learning.claims_control.data_quality_results`
(
  run_id,
  test_name,
  test_status,
  failed_record_count,
  check_time,
  test_description
)
WITH quality_checks AS
(
  SELECT
    'DUPLICATE_CLAIM_IDS' AS test_name,
    (
      SELECT COUNT(*)
      FROM
      (
        SELECT claim_id
        FROM `claims-etl-learning.claims_staging.stg_claims`
        GROUP BY claim_id
        HAVING COUNT(*) > 1
      )
    ) AS failed_record_count,
    'Claim IDs must be unique in the staging table.' AS test_description

  UNION ALL

  SELECT
    'INVALID_CLAIM_STATUS',
    (
      SELECT COUNT(*)
      FROM `claims-etl-learning.claims_staging.stg_claims`
      WHERE claim_status NOT IN ('PAID', 'PENDING', 'DENIED')
         OR claim_status IS NULL
    ),
    'Staging claims must contain only accepted claim statuses.'

  UNION ALL

  SELECT
    'NULL_REQUIRED_FIELDS',
    (
      SELECT COUNT(*)
      FROM `claims-etl-learning.claims_staging.stg_claims`
      WHERE claim_id IS NULL
         OR patient_id IS NULL
         OR claim_amount IS NULL
         OR claim_date IS NULL
         OR updated_at IS NULL
    ),
    'Required staging fields must not contain null values.'

  UNION ALL

  SELECT
    'NEGATIVE_CLAIM_AMOUNT',
    (
      SELECT COUNT(*)
      FROM `claims-etl-learning.claims_staging.stg_claims`
      WHERE claim_amount < 0
    ),
    'Claim amounts in staging must not be negative.'

  UNION ALL

  SELECT
    'STAGING_CLAIM_MISSING_FROM_MART',
    (
      SELECT COUNT(*)
      FROM `claims-etl-learning.claims_staging.stg_claims` AS staging
      LEFT JOIN `claims-etl-learning.claims_mart.fct_claims` AS mart
        ON staging.claim_id = mart.claim_id
      WHERE mart.claim_id IS NULL
    ),
    'Every valid staging claim must be available in the claims mart.'
)
SELECT
  @run_id,
  test_name,
  IF(failed_record_count = 0, 'PASS', 'FAIL'),
  failed_record_count,
  CURRENT_TIMESTAMP(),
  test_description
FROM quality_checks;

ASSERT
(
  SELECT COUNT(*)
  FROM `claims-etl-learning.claims_control.data_quality_results`
  WHERE run_id = @run_id
    AND test_status = 'FAIL'
) = 0
AS 'One or more data-quality checks failed.';