# Claims ETL Pipeline on Google Cloud

## Project Overview

This project demonstrates an incremental claims-data ETL/ELT pipeline using Google Cloud Storage, BigQuery, SQL, Python, and Windows batch scripting.

The pipeline loads incoming claim files, validates the records, separates valid and rejected claims, updates existing claims when a newer record arrives, and publishes reporting-ready data to a BigQuery mart.

## Technologies Used

- Google Cloud Storage
- Google BigQuery
- Google Cloud CLI
- SQL
- Python and Pandas
- Visual Studio Code
- Windows Batch Script

## Architecture

1. CSV files land in Google Cloud Storage.
2. Files are loaded into the BigQuery raw dataset.
3. SQL validates and standardizes incoming records.
4. Valid records are merged into the staging table.
5. Invalid records are merged into the rejected-claims table.
6. Valid claims are joined with patient information.
7. Reporting-ready records are merged into the claims mart.
8. Reconciliation queries verify record counts.

## BigQuery Layers

### Raw Layer

Dataset: `claims_raw`

Stores source data before transformation:

- `claims`
- `patients`
- `claims_incoming`

### Staging Layer

Dataset: `claims_staging`

Contains cleaned and validated records:

- `stg_claims`
- `rejected_claims`
- `stg_patients`
- `rejected_patients`

### Mart Layer

Dataset: `claims_mart`

Contains reporting-ready data:

- `fct_claims`

## Validation Rules

A claim is considered valid when:

- `claim_id` is not null.
- `patient_id` is not null.
- `claim_amount` is greater than or equal to zero.
- `claim_status` is `PAID`, `PENDING`, or `DENIED`.
- Required date and timestamp fields are present.

Claim statuses are standardized using `UPPER(TRIM(claim_status))`.

Invalid records are stored separately for investigation instead of being deleted.

## Incremental Processing

BigQuery `MERGE` statements make the pipeline incremental:

- New valid claims are inserted.
- Existing claims are updated only when the incoming `updated_at` is newer.
- Invalid claims are stored in the rejected table.
- The claims mart is refreshed using validated staging data.

The pipeline is idempotent, so rerunning the same batch does not create duplicate claims.

## Project Structure

```text
claims-etl-learning/
├── data/
│   ├── raw/
│   └── processed/
├── scripts/
│   └── run_incremental_pipeline.cmd
├── sql/
├── src/
│   └── validate_claims.py
├── .gitignore
├── README.md
└── requirements.txt
```

## Running the Pipeline

Open the VS Code terminal from the project folder and activate the Python environment if needed:

```powershell
.venv\Scripts\Activate.ps1
```

Authenticate Google Cloud CLI and select the project:

```powershell
gcloud auth login
gcloud config set project claims-etl-learning
```

Run the pipeline by passing the incoming CSV filename:

```powershell
.\scripts\run_incremental_pipeline.cmd claims_batch_3.csv
```

The script:

1. Uploads the batch file to Cloud Storage.
2. Loads it into `claims_raw.claims_incoming`.
3. Merges valid claims into staging.
4. Merges invalid claims into the rejected table.
5. Updates the claims mart.
6. Runs reconciliation checks.

## Event-Driven Cloud Pipeline

The project also supports automatic processing using Cloud Run and Eventarc.

When a file matching `raw/claims_batch_*.csv` is uploaded to Cloud Storage:

1. Cloud Storage generates an object-finalized event.
2. Eventarc sends the event to the authenticated Cloud Run service.
3. The Python function validates the file path and extension.
4. The file is loaded into `claims_raw.claims_incoming`.
5. BigQuery MERGE statements update valid claims, rejected claims, and the mart.
6. Reconciliation and automated data-quality checks run.
7. The audit table records the execution as `SUCCESS` or `FAILED`.

Files that do not match the expected claims-batch naming pattern are logged and ignored.

### Cloud Components

- Cloud Storage — incoming file landing location
- Eventarc — event routing
- Cloud Run — serverless Python orchestration
- Cloud Build — source build and deployment
- Artifact Registry — container-image storage
- BigQuery — raw, staging, mart, audit, and quality layers
- Cloud Logging — execution and troubleshooting logs

### Automatic Trigger Test

```powershell
gcloud storage cp data\raw\claims_batch_5.csv gs://gilbert-claims-etl-learning-2026/raw/claims_batch_5.csv

## Data Reconciliation

After processing, the pipeline compares record counts across the staging and mart tables to confirm that validated records were loaded successfully.

## Error Handling

The batch script checks each pipeline step. If a command fails, processing stops and displays the failed step. After fixing the issue, the pipeline can safely be rerun because the SQL uses incremental `MERGE` logic.

## Learning Outcomes

This project demonstrates:

- Raw, staging, and mart data architecture
- Data-quality validation
- Rejected-record handling
- SQL transformations
- Incremental loading
- Deduplication using timestamps
- BigQuery `MERGE`
- Fact-table creation
- Reconciliation
- Command-line pipeline automation
- Production-style troubleshooting