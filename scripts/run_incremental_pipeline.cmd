@echo off
setlocal

cd /d "%~dp0.."

set BUCKET=gs://gilbert-claims-etl-learning-2026
set PROJECT=claims-etl-learning
set LOCATION=us-central1
if "%~1"=="" (
    echo ERROR: No incoming filename was provided.
    echo Usage: run_incremental_pipeline.cmd filename.csv
    exit /b 1
)

set BATCH_FILE=%~1
set RAW_TABLE=%PROJECT%:claims_raw.claims_incoming

echo ========================================
echo Starting incremental claims pipeline
echo ========================================

echo.
echo Step 1: Uploading batch file to Cloud Storage...
call gcloud.cmd storage cp data\raw\%BATCH_FILE% %BUCKET%/raw/%BATCH_FILE%

if errorlevel 1 (
    echo ERROR: Cloud Storage upload failed.
    exit /b 1
)

echo.
echo Step 2: Loading batch file into BigQuery raw table...
call bq.cmd load ^
    --project_id=%PROJECT% ^
    --location=%LOCATION% ^
    --source_format=CSV ^
    --skip_leading_rows=1 ^
    --replace=true ^
    %RAW_TABLE% ^
    %BUCKET%/raw/%BATCH_FILE% ^
    "claim_id:STRING,patient_id:STRING,claim_amount:INTEGER,claim_status:STRING,claim_date:DATE,updated_at:TIMESTAMP"

if errorlevel 1 (
    echo ERROR: BigQuery raw-table load failed.
    exit /b 1
)

echo.
echo Step 3: Merging valid claims into staging...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\merge_incoming_claims.sql

if errorlevel 1 (
    echo ERROR: Valid claims merge failed.
    exit /b 1
)

echo.
echo Step 4: Merging rejected claims...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\merge_incoming_rejected_claims.sql

if errorlevel 1 (
    echo ERROR: Rejected claims merge failed.
    exit /b 1
)

echo.
echo Step 5: Updating the claims mart...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\merge_incoming_fct_claims.sql

if errorlevel 1 (
    echo ERROR: Mart merge failed.
    exit /b 1
)

echo.
echo Step 6: Running reconciliation...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\incremental_reconciliation.sql

if errorlevel 1 (
    echo ERROR: Reconciliation failed.
    exit /b 1
)

echo.
echo ========================================
echo Incremental pipeline completed successfully
echo ========================================

endlocal