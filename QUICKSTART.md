# Quickstart

How to run this project locally and deploy it through GitHub Actions. For the project overview, architecture, and analytical context, see [`README.md`](README.md).

## Running locally

### Prerequisites

- Python 3.11 or a compatible Python 3 release.
- A Google Cloud project with BigQuery enabled.
- A service account with the required BigQuery permissions.
- Authorized access to the source ClickHouse database.
- dbt Core with the BigQuery adapter, installed through `requirements.txt`.

### 1. Create an environment

```bash
git clone https://github.com/tduong-p/laplaptech-analysis.git
cd laplaptech-analysis
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure environment variables

The dbt profile expects:

```text
GCP_PROJECT_ID
GCP_SERVICE_ACCOUNT_JSON
BIGQUERY_LOCATION
BIGQUERY_DBT_DATASET
```

`LAPLAPTECH_SOURCE_DATABASE` and `LAPLAPTECH_SOURCE_SCHEMA` are separate — they configure the dbt `source()` declarations in `dbt/models/sources.yml`, not the Python ingestion job. Set them alongside the variables above before running `dbt build`.

Do not commit service-account keys or database credentials.

### 3. Validate and build

```bash
cd dbt
dbt debug
dbt build
```

## GitHub Actions deployment

Configure these repository secrets:

```text
CLICKHOUSE_HOST
CLICKHOUSE_PORT
CLICKHOUSE_USER
CLICKHOUSE_PASSWORD
CLICKHOUSE_DATABASE
CLICKHOUSE_SECURE
GCP_PROJECT_ID
GCP_SERVICE_ACCOUNT_JSON
```

Optional repository variables:

```text
BIGQUERY_LOCATION=asia-southeast1
BIGQUERY_RAW_DATASET=laplaptech_raw
BIGQUERY_DBT_DATASET=laplaptech_dev
RUN_DBT_BUILD=true
```

The workflow:

1. Installs Python and project dependencies.
2. Synchronizes ClickHouse tables to BigQuery.
3. Runs `dbt debug` and `dbt build` when `RUN_DBT_BUILD=true`.
