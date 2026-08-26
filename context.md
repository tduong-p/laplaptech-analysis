# LaplapTech — Product and Clickstream Analytics Context

> Business and analytical context for a personal analytics engineering project built from the LaplapTech learning dataset shared with the Xóm Data community.

## 1. Dataset origin

The dataset comes from the LaplapTech technology-product comparison website and was contributed by [Nguyễn Ngọc Duy Luân (Duy Luân Dễ Thương)](https://www.facebook.com/duyluannice) to the [Xóm Data community](https://www.facebook.com/groups/xomdata).

The original source is an operational ClickHouse database. It contains realistic relational master data, measured laptop benchmark results, and high-volume clickstream events. This combination makes the dataset useful for practicing work that is less polished and more representative of real analytics projects than standard demonstration datasets.

This repository does not redistribute source credentials or the raw database. It is an independent educational and portfolio project, not an official LaplapTech report.

## 2. Product context

LaplapTech aggregates information about electronic devices so visitors can inspect products and compare their specifications and measured performance.

The available product catalog contains fewer than 200 devices. That is too small to represent the full electronics market or directly support production decisions for manufacturers. The behavioral event stream is much denser, however, and can reveal how visitors explore and evaluate the products available on the website.

For that reason, the project is positioned around website, content, and audience decisions rather than market-wide manufacturer strategy.

## 3. Intended analytical audience

The primary audiences are:

- Technology reviewers and content creators.
- The LaplapTech website owner and editorial team.
- Technology-focused media and marketing agencies, such as Schannel.
- Analysts responsible for product content, audience behavior, or website performance.

The analysis should help these audiences understand what visitors care about, how they compare devices, and where product information should be improved.

## 4. Source datasets

| Table | Role | Main analytical value |
|---|---|---|
| `user_event_tracking` | Clickstream fact | Page views, searches, clicks, comparison actions, sorting behavior, sessions, and JSON payloads |
| `laptop_model` | Product master | Laptop identity, product segment flags, screen, battery, weight, CPU/GPU references, visibility, and activity status |
| `laptop_benchmark_result` | Performance fact | Real-world battery results, Geekbench results, benchmark notes, and review content references |
| `brand` | Dimension | Human-readable brand attributes |
| `cpu_model` | Dimension | Human-readable CPU attributes |
| `gpu_model` | Dimension | Human-readable GPU attributes |

Two JSON fields in `user_event_tracking` are particularly important:

- `event_data` contains event-specific attributes such as `device_id`, `device_ids`, `page_name`, search keywords, `sort_by`, and `sort_direction`.
- `device` contains client/device metadata such as operating-system information.

## 5. Business and analytical pain points

### 5.1 Tracking reliability

Before interpreting behavior, the project must establish whether event IDs, timestamps, session IDs, JSON payloads, and event volumes are reliable. Client timestamps may be abnormal, so server-received timestamps are used as the canonical analytical time unless validation proves otherwise.

### 5.2 Product interest

The team needs to distinguish broad product interest from deeper comparison interest:

- A product-detail visit indicates general interest or discovery.
- Appearance in comparison behavior indicates interest in evaluating specifications against alternatives.

These are related signals but should not be presented as the same metric.

### 5.3 Comparison context

Products observed in the same session were not necessarily displayed in the same comparison table. Session-level device combinations can support exploratory interest analysis, but exact comparisons should use event payloads containing `device_ids` whenever available.

### 5.4 Product-data coverage

The source also records product creation and updates. This makes it possible to evaluate whether the catalog keeps pace with audience attention, identify high-interest products with missing information, and prioritize additional data collection.

### 5.5 Content opportunity

Behavior and product data can indicate topics that deserve attention, but a defensible content-gap analysis also requires a content inventory containing existing articles or videos, publication dates, formats, and product coverage. Without that dataset, the project should report audience interest and data gaps—not claim that content is missing.

## 6. Analyst responsibility

The analyst is responsible for turning open-ended stakeholder concerns into testable ad hoc questions, validating the source data, defining metric grain, and promoting stable logic into reusable Silver and Gold models.

The recommended workflow is:

1. Explore the source with ad hoc queries.
2. Validate assumptions, keys, timestamps, and JSON structures.
3. Define the grain and business meaning of each metric.
4. Move reusable transformations into Silver dbt models and keep one-off logic inside Gold marts.
5. Expose reporting-ready metrics through Gold marts.
6. Visualize Gold models in Power BI or Looker Studio.
7. Document limitations so exploratory associations are not presented as causal findings.

## 7. Ad hoc analysis backlog

Only questions already raised during project exploration are included below.

### Data quality and foundations

1. Are event identifiers duplicated or missing?
2. Is `session_id` reliable, and can one session be associated with multiple users?
3. Which event timestamp should be used, and where are the timestamp anomalies?
4. Are there missing dates or unusual spikes in daily event volume?

### User behavior

5. How should event names be grouped into traffic, discovery, comparison, authentication, and other behavior categories?
6. What is the conversion and drop-off across the product-view and comparison funnel?
7. Which operating systems are represented across user sessions?

### Product interest and comparison

8. Which products receive the most product-detail traffic?
9. Which products are most frequently involved in comparison behavior, deduplicated within each session?
10. Which product segments are commonly considered within the same session?
11. Which specifications do visitors sort by during comparison, and in which direction?
12. Which product-segment pairs are associated with each sorting criterion when exact `device_ids` are available in the event payload?

### Product and content priorities

13. Which products combine high current interest, increasing interest, and incomplete specifications?
14. Is the product catalog being updated quickly enough to follow changes in audience attention?
15. Which product groups have the largest information gaps and should be prioritized for further data collection?
16. Do devices with stronger measured battery performance receive different levels of views or comparison interest than gaming-oriented or high-benchmark devices?

## 8. Core analytical definitions

### General product interest

A valid event with `page_name = 'DeviceDetail'` and a valid `device_id`. This represents attention expressed through opening a product-detail page.

### Comparison interest

A product appearing in comparison-related behavior. Repeated occurrences of the same product within one session are counted once for session-level comparison interest.

### Exact comparison sort context

For `comparison_chart_sort_selection`, the JSON payload may contain the exact `device_ids`, sorting criterion, and direction. This event-level payload is preferred over reconstructing a comparison set from all events in the session.

### Product-data update priority

The current analytical heuristic combines product interest, recent interest trend, and overall specification/content completeness (a flat share of missing fields, not a critical/important/optional ranking). The score supports prioritization; it is not yet a validated business rule.

## 9. Expected analytics outputs

The project produces Gold marts for:

- Daily website KPIs.
- Behavioral funnel performance.
- Product-detail traffic.
- Most-compared products.
- Monthly product interest and trend.
- Product segment pairs considered together.
- Comparison sorting criteria.
- Product-data quality and update priority.
- User operating-system distribution.

These marts are intended to support a report narrative that progresses from data reliability, to audience behavior, to product interest, to actionable content and data-maintenance priorities.

## 10. Known analytical limitations

- The catalog is small and cannot represent the entire electronics market.
- Session co-occurrence is not proof that two products appeared in the same comparison table.
- Website behavior indicates attention, not purchase intent or market demand.
- Interest scores and update-priority weights require calibration against real distributions and stakeholder feedback.
- Content-opportunity claims require an additional content-inventory dataset.
- Findings describe observed associations and should not be framed as causal effects.

## 11. Project documents

- [`README.md`](README.md): architecture, implementation, setup, and repository showcase.
- [`DEVLOG.md`](DEVLOG.md): dated decisions and the evolution of the project reasoning, including the reporting narrative and Power BI structure.
