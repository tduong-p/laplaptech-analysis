import os
import json
from typing import Iterable

import clickhouse_connect
from google.cloud import bigquery


FULL_REFRESH_TABLES = [
    "brand",
    "cpu_model",
    "gpu_model",
    "laptop_benchmark_result",
    "laptop_model",
]

INCREMENTAL_TABLES = {
    "user_event_tracking": "event_received_on_server_timestamp",
}


def require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def get_clickhouse_client():
    return clickhouse_connect.get_client(
        host=require_env("CLICKHOUSE_HOST"),
        port=int(os.getenv("CLICKHOUSE_PORT", "8443")),
        username=require_env("CLICKHOUSE_USER"),
        password=require_env("CLICKHOUSE_PASSWORD"),
        database=os.getenv("CLICKHOUSE_DATABASE", "laplaptech"),
        secure=os.getenv("CLICKHOUSE_SECURE", "true").lower() == "true",
    )


def get_bigquery_client():
    service_account_json = os.getenv("GCP_SERVICE_ACCOUNT_JSON")
    if service_account_json:
        service_account_info = json.loads(service_account_json)
        return bigquery.Client.from_service_account_info(
            service_account_info,
            project=require_env("GCP_PROJECT_ID"),
        )

    return bigquery.Client(project=require_env("GCP_PROJECT_ID"))


def table_id(table_name: str) -> str:
    return (
        f"{require_env('GCP_PROJECT_ID')}."
        f"{os.getenv('BIGQUERY_RAW_DATASET', 'laplaptech_raw')}."
        f"{table_name}"
    )


def load_dataframe(
    bq_client: bigquery.Client,
    df,
    destination_table: str,
    write_disposition: str,
) -> None:
    if df.empty:
        print(f"Skip {destination_table}: no rows")
        return

    job_config = bigquery.LoadJobConfig(
        autodetect=True,
        write_disposition=write_disposition,
    )
    job = bq_client.load_table_from_dataframe(
        df,
        destination_table,
        job_config=job_config,
    )
    job.result()
    print(f"Loaded {len(df)} rows into {destination_table}")


def get_max_loaded_timestamp(
    bq_client: bigquery.Client,
    destination_table: str,
    timestamp_column: str,
) -> str | None:
    try:
        query_job = bq_client.query(
            f"SELECT CAST(MAX({timestamp_column}) AS STRING) AS max_ts "
            f"FROM `{destination_table}`"
        )
        rows = list(query_job.result())
        return rows[0]["max_ts"] if rows and rows[0]["max_ts"] else None
    except Exception as exc:
        print(f"Could not read watermark from {destination_table}: {exc}")
        return None


def sync_full_refresh_tables(
    ch_client,
    bq_client: bigquery.Client,
    tables: Iterable[str],
) -> None:
    for table_name in tables:
        df = ch_client.query_df(f"SELECT * FROM {table_name}")
        load_dataframe(
            bq_client=bq_client,
            df=df,
            destination_table=table_id(table_name),
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )


def sync_incremental_tables(ch_client, bq_client: bigquery.Client) -> None:
    for table_name, timestamp_column in INCREMENTAL_TABLES.items():
        destination_table = table_id(table_name)
        max_loaded_timestamp = get_max_loaded_timestamp(
            bq_client=bq_client,
            destination_table=destination_table,
            timestamp_column=timestamp_column,
        )

        where_clause = ""
        if max_loaded_timestamp:
            where_clause = (
                f"WHERE {timestamp_column} > parseDateTimeBestEffort("
                f"'{max_loaded_timestamp}')"
            )

        query = f"""
            SELECT *
            FROM {table_name}
            {where_clause}
            ORDER BY {timestamp_column}
        """
        df = ch_client.query_df(query)
        load_dataframe(
            bq_client=bq_client,
            df=df,
            destination_table=destination_table,
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        )


def main() -> None:
    ch_client = get_clickhouse_client()
    bq_client = get_bigquery_client()

    sync_full_refresh_tables(ch_client, bq_client, FULL_REFRESH_TABLES)
    sync_incremental_tables(ch_client, bq_client)


if __name__ == "__main__":
    main()
