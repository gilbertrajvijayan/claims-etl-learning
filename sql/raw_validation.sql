-- Check total raw record count
SELECT COUNT(*) AS total_records
FROM `claims-etl-learning.claims_raw.claims`;

-- Find duplicate claim IDs
SELECT
    claim_id,
    COUNT(*) AS duplicate_count
FROM `claims-etl-learning.claims_raw.claims`
GROUP BY claim_id
HAVING COUNT(*) > 1;

-- Find missing claim amounts
SELECT
    claim_id,
    claim_amount
FROM `claims-etl-learning.claims_raw.claims`
WHERE claim_amount IS NULL;

-- Find negative claim amounts
SELECT
    claim_id,
    claim_amount
FROM `claims-etl-learning.claims_raw.claims`
WHERE claim_amount < 0;

-- Find missing patient IDs
SELECT
    claim_id,
    patient_id
FROM `claims-etl-learning.claims_raw.claims`
WHERE patient_id IS NULL;

-- Display distinct source statuses
SELECT DISTINCT
    claim_status
FROM `claims-etl-learning.claims_raw.claims`
ORDER BY claim_status;

-- Find invalid statuses after standardization
SELECT
    claim_id,
    claim_status AS original_status,
    UPPER(TRIM(claim_status)) AS standardized_status
FROM `claims-etl-learning.claims_raw.claims`
WHERE UPPER(TRIM(claim_status))
      NOT IN ('PAID', 'PENDING', 'DENIED');