SELECT
    (
        SELECT COUNT(*)
        FROM `claims-etl-learning.claims_raw.claims_incoming`
    ) AS incoming_count,

    (
        SELECT COUNT(*)
        FROM `claims-etl-learning.claims_raw.claims_incoming`
        WHERE claim_id IS NOT NULL
          AND patient_id IS NOT NULL
          AND claim_amount IS NOT NULL
          AND claim_amount >= 0
          AND UPPER(TRIM(claim_status))
              IN ('PAID', 'PENDING', 'DENIED')
    ) AS valid_incoming_count,

    (
        SELECT COUNT(*)
        FROM `claims-etl-learning.claims_raw.claims_incoming`
        WHERE claim_id IS NULL
           OR patient_id IS NULL
           OR claim_amount IS NULL
           OR claim_amount < 0
           OR UPPER(TRIM(claim_status))
              NOT IN ('PAID', 'PENDING', 'DENIED')
    ) AS rejected_incoming_count;