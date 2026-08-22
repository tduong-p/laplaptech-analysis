# LaplapTech Analytics Pipeline

Personal analytics engineering project: ClickHouse -> Python ingestion -> BigQuery -> dbt (Bronze/Silver/Gold) -> Power BI / Looker Studio. Analyzes clickstream + product data from the LaplapTech laptop-comparison website.

Read [context.md](context.md) first for business questions, stakeholders, and metric definitions before writing or reviewing analytical logic — the analytical grain and definitions there (e.g. "product interest" vs "comparison interest") are load-bearing and easy to get wrong from the schema alone.

## Layout

- `ingestion/clickhouse_to_bigquery.py` — extracts from ClickHouse, loads into BigQuery.
- `dbt/` — dbt Core project, profile `clickhouse_da_pipeline`.
  - `models/bronze` (views), `models/silver` (views), `models/gold` (tables, marts).
  - Silver models replaced the old `models/intermediate` layer (see recent git history — intermediate models were deleted and folded into `silver_*`).
- `docs/report-storytelling-plan.md` — reporting/narrative structure.
- `DEVLOG.md` — dated decision log; check before assuming why something is built a certain way.
- `.github/workflows/sync-clickhouse-to-bigquery.yml` — daily scheduled ingestion (02:00 UTC).

## Conventions

- dbt naming: `bronze_*`, `silver_*`, `mart_*` (gold). No more `int_*` intermediate models.
- Canonical event time is the **server-received timestamp**, not client timestamps (client timestamps can be unreliable — see context.md §5.1).
- Findings should be reported as observed associations, not causal claims — the catalog is small (<200 devices) and not representative of the full market.

## Working here

- Python deps: `requirements.txt` (clickhouse-connect, dbt-core, dbt-bigquery, pandas, pyarrow).
- Run dbt from the `dbt/` directory (`dbt build`, `dbt run`, `dbt test`).
