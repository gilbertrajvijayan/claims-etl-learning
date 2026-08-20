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
set "RUN_ID=%RANDOM%-%RANDOM%-%RANDOM%"

echo ========================================
echo Starting incremental claims pipeline
echo ========================================

echo.
echo Creating pipeline audit record...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% --parameter=run_id:STRING:%RUN_ID% --parameter=batch_file:STRING:%BATCH_FILE% < sql\audit_pipeline_start.sql

if errorlevel 1 (
    echo ERROR: Unable to create pipeline audit record.
    exit /b 1
)

echo Pipeline Run ID: %RUN_ID%
echo Step 1: Uploading batch file to Cloud Storage...
call gcloud.cmd storage cp data\raw\%BATCH_FILE% %BUCKET%/raw/%BATCH_FILE%

if errorlevel 1 (
    set "ERROR_STEP=STEP_1_CLOUD_STORAGE_UPLOAD"
    set "ERROR_MESSAGE=Cloud Storage upload failed."
    goto :pipeline_failed
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
    set "ERROR_STEP=STEP_2_RAW_TABLE_LOAD"
    set "ERROR_MESSAGE=Loading the incoming file into the BigQuery raw table failed."
    goto :pipeline_failed
)

echo.
echo Step 3: Merging valid claims into staging...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\merge_incoming_claims.sql

if errorlevel 1 (
    set "ERROR_STEP=STEP_3_VALID_CLAIMS_MERGE"
    set "ERROR_MESSAGE=Merging valid claims into staging failed."
    goto :pipeline_failed
)

echo.
echo Step 4: Merging rejected claims...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\merge_incoming_rejected_claims.sql

if errorlevel 1 (
    set "ERROR_STEP=STEP_4_REJECTED_CLAIMS_MERGE"
    set "ERROR_MESSAGE=Merging rejected claims failed."
    goto :pipeline_failed
)

echo.
echo Step 5: Updating the claims mart...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\merge_incoming_fct_claims.sql

if errorlevel 1 (
    set "ERROR_STEP=STEP_5_MART_MERGE"
    set "ERROR_MESSAGE=Updating the claims mart failed."
    goto :pipeline_failed
)

echo.
echo Step 6: Running reconciliation...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% < sql\incremental_reconciliation.sql

if errorlevel 1 (
    set "ERROR_STEP=STEP_6_RECONCILIATION"
    set "ERROR_MESSAGE=Pipeline reconciliation failed."
    goto :pipeline_failed
)

echo.
echo Updating pipeline audit record...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% --parameter=run_id:STRING:%RUN_ID% < sql\audit_pipeline_success.sql

if errorlevel 1 (
    echo ERROR: Unable to update the pipeline audit record.
    exit /b 1
)

echo.
echo ========================================
echo Incremental pipeline completed successfully
echo ========================================

endlocal
exit /b 0

:pipeline_failed
echo.
echo Recording pipeline failure...
call bq.cmd query --use_legacy_sql=false --location=%LOCATION% "--parameter=run_id:STRING:%RUN_ID%" "--parameter=error_step:STRING:%ERROR_STEP%" "--parameter=error_message:STRING:%ERROR_MESSAGE%" < sql\audit_pipeline_failed.sql
if errorlevel 1 (
    echo WARNING: The pipeline failed, and the audit record could not be updated.
)

echo.
echo ERROR: Pipeline failed during %ERROR_STEP%.
echo %ERROR_MESSAGE%
exit /b 1