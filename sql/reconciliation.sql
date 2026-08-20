-- Confirm that all raw records are accounted for

SELECT
    (
        SELECT COUNT(*)
        FROM `claims-etl-learning.claims_raw.claims`
    ) AS raw_count,

    (
        SELECT COUNT(*)
        FROM `claims-etl-learning.claims_staging.stg_claims`
    ) AS valid_count,

    (
        SELECT COUNT(*)
        FROM `claims-etl-learning.claims_staging.rejected_claims`
    ) AS rejected_count;