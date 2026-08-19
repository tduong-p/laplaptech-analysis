# LaplapTech Analytics Development Log

This document replaces the original personal notes. It preserves not only implementation events, but also the reasoning that led to the current analytical scope, model grains, metrics, limitations, and open questions.

Dated entries are based on Git history where possible. Work completed before the first repository commit is grouped as **Undated exploration** rather than assigned an invented date.

## Current project thesis

LaplapTech is a product aggregation and comparison website associated with a technology reviewer. Its catalog contains fewer than 200 devices, while its event stream contains a relatively dense record of user actions.

This imbalance determines the project direction:

- The catalog is too small to represent the full electronics market.
- The data should not be used for manufacturer-level production, pricing, or supply-chain decisions.
- The event stream is still useful for understanding the audience already using LaplapTech.
- The most appropriate stakeholders are technology reviewers, the website owner, content teams, and marketing agencies such as Schannel.

The project is therefore an audience and content-operations analytics project, not a market-sizing project.

The central reasoning chain is:

```text
What do users view?
    -> What do they actively compare?
        -> Which trade-offs and specifications matter?
            -> What content or product information should be prioritized?
```

## 2026-08-19 - Repository, documentation, and BI architecture

### Repository restructuring

- Created an isolated local repository at `/Users/duongpt/Developer/laplaptech-analysis`.
- Preserved the existing Git history and GitHub remote.
- Kept the previous repository under `Learning` as a safety copy.
- Flattened the project so the portfolio README is visible at the GitHub repository root.
- Moved the dbt project to `dbt/`, ingestion to `ingestion/`, and reporting notes to `docs/`.
- Removed committed Obsidian settings, dbt user identifiers, and disabled starter example models from the new repository.
- Replaced the workspace allowlist `.gitignore` with a normal project-level ignore file.
- Updated GitHub Actions paths for the flattened structure.

### Documentation decision

- Added an English portfolio README describing business context, architecture, grains, model outputs, deployment, limitations, and next steps.
- Converted the original personal notes into this development log rather than reducing them to a short changelog.
- Preserved the detailed report narrative separately in `docs/report-storytelling-plan.md`.

### BI architecture decision

The selected architecture is:

```text
ClickHouse
-> BigQuery raw
-> dbt transformations and marts
-> Power BI semantic model
-> report visuals
```

The decision was not to move all transformations into Power BI.

Reasoning:

- JSON extraction, timestamp normalization, deduplication, and sessionization define the meaning and grain of the data.
- These rules should remain reusable outside one `.pbix` file.
- dbt makes transformations reviewable in Git, testable, documentable, and reusable by Power BI or Looker Studio.
- Power BI is better suited to relationships, filter-context calculations, dynamic ranking, period comparison, and visualization.
- Import mode is appropriate for the current mart sizes and avoids issuing a BigQuery query for every report interaction.

Responsibility split:

```text
dbt / BigQuery
- data cleaning
- JSON extraction
- sessionization
- event classification
- grain definition
- reusable aggregations
- data-quality scoring

Power BI
- star-schema relationships
- date table
- DAX measures
- filter-context calculations
- report interaction
- visualization and storytelling
```

## 2026-08-17 - Ad hoc analysis, funnel, timestamp repair, and storytelling

Git history:

```text
7480a54  Adding 2 ad-hoc: User OS + Behavior funnel
8e6e266  Fix event timestamp conversion for BigQuery
59af2de  Adding adhoc, completed storytelling plan
```

### Timestamp reasoning

The event source exposes client-local and server-received timestamps.

Initial investigation found cases where client-local time differed from server-received time by days. Possible causes include incorrect client clocks, timezone handling, malformed values, or tracking inconsistencies.

Decision:

```text
canonical event time = event_received_on_server_timestamp
analytics timezone   = Asia/Ho_Chi_Minh
```

Client-local time should be retained for quality diagnostics but should not drive daily traffic, funnel, or trend reporting.

The principle is more important than the exact implementation: a report should use one documented canonical timestamp rather than silently mixing client and server time.

### Behavioral funnel reasoning

The proposed behavioral journey is:

```text
Device detail view
-> search or load more
-> add to comparison
-> select device for comparison
-> sort comparison chart
```

Two possible funnel definitions were considered:

1. **Presence funnel:** a session contains all relevant event names, regardless of order.
2. **Sequential funnel:** each next event occurs at or after the previous event.

The implemented funnel is sequential because it better represents progression. Each session is counted at most once per step.

Important interpretation:

- A large drop after search can indicate irrelevant results or insufficient discovery.
- A large drop after add-to-comparison can indicate difficulty selecting the next product.
- A low chart-sort rate can indicate either low need for advanced comparison or weak discoverability of sorting controls.
- Funnel drop-off is not automatically a product problem; it is a diagnostic signal requiring context.

### User operating-system ad hoc

Operating system was added as a session-level analytical dimension. It may later help answer whether funnel behavior differs by platform.

The grain must remain explicit: one session can contain multiple events and potentially inconsistent OS values. The model should not count every raw event as a new user or session.

### Storytelling structure

The report was designed around a sequence of business questions:

```text
1. Can the behavioral data be trusted?
2. How active is the website?
3. Which products attract attention?
4. Which products require deeper comparison?
5. What trade-offs and specifications matter?
6. How far do users progress through the comparison journey?
7. Which product records should be updated first?
```

The report should distinguish:

- **Observation:** what the data shows.
- **Interpretation:** a plausible explanation.
- **Recommendation:** the proposed action.
- **Limitation:** what the data cannot prove.

An unfinished ad hoc question must be presented as a next analytical question, not as a completed insight.

## 2026-08-16 - Migration from ClickHouse SQL to BigQuery SQL

Git history:

```text
8e2fb87  Migrate dbt models to BigQuery SQL
```

### Why the migration was needed

The initial dbt models were developed against ClickHouse syntax. After choosing BigQuery as the cloud warehouse, several models could parse as Jinja but would fail as BigQuery SQL.

Function mapping:

```text
ClickHouse                    BigQuery
JSONExtractString             JSON_VALUE
groupUniqArray                ARRAY_AGG(DISTINCT ...)
arrayJoin                     UNNEST
countDistinct                 COUNT(DISTINCT ...)
toDate                        DATE
toDateTime                    TIMESTAMP
toUInt64OrNull                SAFE_CAST(... AS INT64)
```

### Corrections made during migration

- Fixed references to a nonexistent comparison intermediate model.
- Removed trailing commas that invalidated `SELECT` statements.
- Added missing `page_views` and `viewing_sessions` metrics.
- Standardized JSON product IDs as `INT64` before dimension joins.
- Standardized nullable source Boolean values.
- Corrected CPU and GPU joins to use `cpu_model_id` and `gpu_model_id`.
- Configured bronze, silver, and intermediate models as views.
- Configured gold models as tables that dbt rebuilds rather than appends to.
- Disabled dbt starter examples.
- Corrected `DBT_PROFILES_DIR` for GitHub Actions.

### Idempotency discussion

dbt model reruns do not append duplicate gold rows under the current materializations:

```text
bronze / silver / intermediate views -> definitions are replaced
gold tables                           -> tables are rebuilt
raw dimensions                        -> WRITE_TRUNCATE
raw events                            -> incremental WRITE_APPEND
```

The remaining idempotency risk is raw event ingestion:

- Sequential runs use a timestamp watermark and generally avoid duplicates.
- Concurrent runs can read the same watermark and append the same events.
- Late-arriving events older than the watermark can be missed.
- The long-term fix is staging plus `MERGE ON id` and workflow concurrency protection.

### Validation approach

- `dbt parse` validates project configuration, Jinja, tests, and DAG references.
- Static parsing checks BigQuery SQL syntax without cloud credentials.
- A complete `dbt build` against BigQuery is still required to validate actual source column types and data behavior.

## 2026-08-15 - Automated ClickHouse-to-BigQuery pipeline

Git history:

```text
284a91b  Add LapLapTech BigQuery sync workflow
```

### Ingestion design

The Python ingestion job loads:

```text
Full refresh
- brand
- cpu_model
- gpu_model
- laptop_benchmark_result
- laptop_model

Incremental
- user_event_tracking
```

Dimension-like product tables are small, so full refresh keeps the implementation understandable. The event table is larger and therefore uses a server-timestamp watermark.

### BigQuery datasets

```text
laplaptech_raw  -> ingested source tables
laplaptech_dev  -> dbt models and marts
```

The datasets use `asia-southeast1` unless overridden.

### GitHub Actions

The workflow supports:

- Scheduled execution at `02:00 UTC` every day.
- Manual execution with `workflow_dispatch`.
- ClickHouse and GCP credentials stored as repository secrets.
- Optional dbt execution controlled by `RUN_DBT_BUILD`.

The local computer does not need to remain powered on for scheduled GitHub Actions runs.

### Original repository-scope problem

The first Git repository was initialized at the parent `Learning` directory. An allowlist `.gitignore` was created so unrelated projects would not be pushed.

This worked technically but produced an awkward portfolio structure in which the actual project lived under `LalapTech-Pipeline-Project/`. The repository was later isolated and flattened on 2026-08-19.

## Undated exploration before 2026-08-15

### Learning approach

The project was used to learn concepts when they became necessary rather than studying every topic in advance.

Knowledge areas picked up through implementation:

- ClickHouse schema inspection and event queries.
- SQL grouping, joins, CTEs, arrays, JSON, window functions, nulls, and duplicates.
- dbt `source()`, `ref()`, materializations, tests, docs, and lineage.
- Entity, key, and grain definition.
- Medallion architecture and star-schema concepts.
- Sessions, funnels, active users, product interest, and comparison behavior.
- Metric definitions before dashboard construction.
- BI storytelling using evidence, interpretation, action, and limitation.

### Why medallion layers were selected

The raw event table is not directly suitable for dashboarding. Querying raw JSON separately in every visual would create inconsistent definitions and make debugging difficult.

Layer responsibilities:

```text
Source
- declares physical BigQuery raw tables

Bronze
- preserves source data with minimal transformation

Silver
- standardizes types, timestamps, names, Boolean values, and entities

Intermediate
- implements reusable behavioral logic and explicit grains

Gold
- exposes reporting-ready metrics and dimensions
```

Medallion and star schema are not competing approaches:

- Medallion describes transformation maturity.
- Star schema describes analytical relationships between facts and dimensions.
- A project can transform data through bronze/silver/intermediate layers and expose a star-like semantic model at the gold or BI layer.

### Grain-first modeling

Before calculating a metric, the project records what one row represents.

Examples:

```text
silver_user_event_tracking
= one tracked event

int_session_activity
= one session

int_comparison_event
= one session + one distinct product

int_product_interest_daily
= one date + one product

mart_product_interest
= one week + one product
```

This prevents common errors such as summing session counts across products and calling the result total website sessions.

## Analytical question log

The following section preserves the original sequence of ad hoc questions and how each one influenced the data model.

### 1. Event-tracking data quality

Question:

> Is `user_event_tracking` reliable enough for analysis?

Checks:

- Null `user_id`, `session_id`, `event_name`, and timestamp values.
- Duplicate IDs and duplicate events.
- Available date range and missing dates.
- Event-volume spikes or sudden gaps.
- Required JSON keys by event type.

Downstream impact:

- Canonical event model.
- Daily KPI mart.
- Limitations shown in the report.

### 2. Reliability of `session_id`

Question:

> Does `session_id` represent one visit and a usable comparison context?

Checks:

- Percentage of events with null session IDs.
- Sessions associated with multiple user IDs.
- Extremely long sessions or implausible event counts.

Decision:

- Use `session_id` as the current grouping key.
- Treat it as an approximation where exact comparison membership is unavailable.
- Consider `user_id + session_id` if collisions are found.

### 3. Local timestamp versus server timestamp

Question:

> Which timestamp should drive analytics?

Decision:

- Use server-received time as canonical.
- Keep local time for anomaly detection and tracking diagnostics.

### 4. Event volume by day

Question:

> How do traffic and interaction change over time?

Checks:

- Daily events, sessions, and users.
- Event mix by day.
- Missing dates and unusual peaks.

Downstream model:

- `mart_daily_site_kpis`.

### 5. Event behavior classification

Mapping:

```text
pageview                              -> traffic
load_more_device_home                 -> discovery
search_for_device                     -> discovery
add_to_comparison                     -> comparison
select_device_for_comparison          -> comparison
comparison_chart_sort_selection       -> comparison
user_login                            -> authentication
everything else                       -> other
```

Downstream model:

- `int_event_behavior`.

### 6. Behavioral funnel

Question:

> How far do users progress from product viewing into advanced comparison?

Downstream models:

- `int_session_funnel`.
- `mart_behavior_funnel_daily`.

### 7. Product interest

Two signals were intentionally separated:

```text
General interest
= opening or interacting with a product-detail page

Specification interest
= bringing a product into comparison behavior
```

Reasoning:

- A page view can represent curiosity, navigation, or broad awareness.
- Comparison behavior suggests deeper evaluation of specifications.
- Neither signal alone should be labeled purchase intent.

Downstream models:

- `int_product_interest_daily`.
- `int_product_interest_trend`.
- `mart_product_interest`.

### 8. Products and segments compared together

Initial approach:

- Treat a session as an approximate comparison group.
- Deduplicate product IDs within the session.
- Join products to `usage_segment`.
- Generate unordered pairs with `LEAST` and `GREATEST`.

Limitation:

> Two products occurring in the same session are not guaranteed to have appeared in the same comparison table.

Downstream models:

- `int_comparison_segment_pair`.
- `mart_comparison_segment_pairs`.

### 9. Comparison sort criteria

Question:

> Which specification does the user actively sort by?

The observed payload is:

```json
{
  "device_ids": ["27", "44", "24", "46", "35", "37", "17", "49", "22", "25"],
  "sort_by": "office_battery_life",
  "sort_direction": "asc"
}
```

This was a key analytical improvement because `device_ids` identifies the exact products present when sorting occurred.

Downstream models:

- `int_comparison_sort_event`.
- `int_comparison_sort_segment_pair`.
- `mart_comparison_sort_criteria`.

### 10. Segment pairs combined with sort criteria

Question:

> For a given pair of product segments, which criteria are used most often?

Potential interpretations:

```text
gaming vs mobile + battery-life sorting
-> users may be evaluating performance against portability

gaming vs gaming + GPU sorting
-> users may prioritize graphics performance within the same segment
```

These remain interpretations until validated against actual frequencies and product context.

### 11. Content opportunity

Initial idea:

```text
content opportunity
= high interest
+ positive trend
+ underused content angle
```

Scope correction:

Interest and growth alone can identify products receiving attention, but they cannot prove a content gap.

A true content-opportunity model requires a content inventory containing at least:

- Topic or title.
- Product IDs or segments covered.
- Content format.
- Publication date.
- Last update date.
- Existing performance if available.

Decision:

- Do not label a popularity ranking as `content_opportunity`.
- Keep this as a future analytical direction until content inventory is available.

### 12. Product-data update priority

Question:

> Which products have strong demand signals but incomplete product information?

Candidate completeness fields:

```text
CPU and GPU models
CPU and GPU TDP
battery capacity
screen size and dimensions
screen PPI
laptop and charger weight
thumbnail
benchmark results
review video
```

Fields should not all have equal importance. They can be grouped as:

```text
critical
important
optional
```

Priority concept:

```text
high product views or comparisons
+ positive interest trend
+ important missing fields
= higher update priority
```

Downstream models:

- `int_product_data_completeness`.
- `mart_product_data_quality_priority`.

## Reporting narrative

The proposed report sequence is:

### Page 1 - Data reliability

Purpose:

- Establish whether event, session, and time fields can support analysis.
- Document the canonical timestamp.
- Surface missing or anomalous tracking periods.

### Page 2 - Website activity overview

Purpose:

- Show total events, sessions, users, product views, and comparison-session rate.
- Show daily activity and normalized behavior mix.
- Lead into the products responsible for observed changes.

### Page 3 - Product interest

Purpose:

- Rank product-detail interest.
- Compare brand and product-segment demand.
- Show interest trends without claiming market-wide popularity.

### Page 4 - Comparison interest

Purpose:

- Identify products receiving deeper specification-oriented attention.
- Contrast view rank with comparison rank.

Interpretation matrix:

| Views | Comparison | Possible interpretation |
|---|---|---|
| High | High | Broad attention and deeper evaluation |
| High | Low | Awareness or information-seeking |
| Low | High | Niche but specification-focused interest |
| Low | Low | Low priority within the observed audience |

### Page 5 - Comparison context

Purpose:

- Show product segments considered together.
- Show criteria actively used to sort those exact comparison sets.

### Page 6 - Behavioral funnel

Purpose:

- Show progression and drop-off from product view to advanced comparison interaction.

### Page 7 - Product-data coverage

Purpose:

- Contrast interest with completeness.
- Produce an operational update queue for the website.

### Final message

```text
Views show what attracts attention.
Comparisons show what requires deeper evaluation.
Sort criteria show which specifications matter in that evaluation.
Completeness shows whether the website can satisfy that demand.
```

## Open technical and analytical items

1. Replace watermark-only append ingestion with staging and `MERGE ON id`.
2. Add GitHub Actions concurrency protection.
3. Validate late-arriving event behavior.
4. Quantify null and multi-user session IDs.
5. Add a persistent event-quality mart or monitoring query.
6. Run every model and test against the live BigQuery schema.
7. Review weekly interest distributions before finalizing weights.
8. Confirm whether all DeviceDetail events represent a page view or whether a more specific event name is required.
9. Build the Power BI date dimension, relationships, and DAX measures.
10. Add final report screenshots, findings, and recommendations to the README.
11. Add a content inventory before implementing a real content-opportunity model.
