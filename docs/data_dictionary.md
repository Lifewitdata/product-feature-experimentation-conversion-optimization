# Data Dictionary

All files live in `data/`. Grain, row counts, and value sets below were verified directly against the shipped CSVs (50,000 users; experiment window 1–28 July 2026). All data is synthetic.

## `users.csv` — one row per user · 50,000 rows

| Column | Type | Definition | Values / notes |
|---|---|---|---|
| `user_id` | string (key) | Unique user identifier; join key for every other table | 50,000 distinct |
| `age_group` | string | Age band at signup | `18-24`, `25-34`, `35-44`, `45-54`, `55+` |
| `country` | string | User's market | `Australia`, `Canada`, `India`, `United Kingdom`, `United States` |
| `signup_date` | date | Account creation date | 2024-01-01 to 2026-06-18 |
| `customer_segment` | string | Lifecycle segment at assignment | `New`, `Active`, `Returning` |
| `device_type` | string | Primary device | `Desktop`, `Mobile`, `Tablet` |

## `experiment_assignments.csv` — one row per assigned user · 50,000 rows

| Column | Type | Definition | Values / notes |
|---|---|---|---|
| `user_id` | string (key) | Assigned user; exactly one row per user — a user is never in both groups | 50,000 distinct |
| `experiment_id` | string | Experiment identifier | `EXP_CHECKOUT_2026_01` (single experiment in this dataset) |
| `experiment_group` | string | Analysis group | `control` (24,904 users), `treatment` (25,096 users) |
| `assignment_date` | date | Date the user entered the experiment | 2026-07-01 to 2026-07-28 |
| `feature_variant` | string | The experience the user actually received | `standard_checkout` (control), `one_tap_checkout` (treatment) |

## `experiment_metrics.csv` — one row per assigned user · 50,000 rows · the analysis table

All flags are user-level 0/1 rollups over the experiment window — this is the table every KPI in `reports/` is computed from.

| Column | Type | Definition |
|---|---|---|
| `user_id` | string (key) | Assigned user |
| `experiment_group` | string | `control` / `treatment` (denormalised from assignments for convenience) |
| `checkout_started` | int 0/1 | 1 if the user started checkout at least once |
| `payment_attempted` | int 0/1 | 1 if the user attempted payment at least once |
| `payment_completed` | int 0/1 | 1 if a payment completed |
| `converted` | int 0/1 | **Primary outcome.** 1 if the user completed a purchase (`payment_completed = 1`) |
| `purchase_count` | int | Number of completed purchases (0–6) |
| `revenue` | float | Total revenue from this user in the window, in dollars; 0 for non-buyers. Max 927.42. Zero share: 66.3% control / 61.0% treatment — exactly the non-converter share |
| `payment_failure` | int 0/1 | Guardrail. 1 if the user hit at least one payment failure |
| `support_contact` | int 0/1 | Guardrail. 1 if the user contacted support at least once |

## `product_events.csv` — one row per event · 293,364 rows

| Column | Type | Definition | Values / notes |
|---|---|---|---|
| `event_id` | string (key) | Unique event identifier | |
| `user_id` | string | User who fired the event | all 50,000 users appear |
| `event_name` | string | Event type | `app_open`, `product_view`, `checkout_started`, `feature_clicked`, `payment_attempted`, `purchase_completed`, `one_tap_feature_view` (treatment-only) |
| `event_timestamp` | timestamp | When the event fired | 2026-07-01 00:00 to 2026-07-28 01:17 |
| `session_id` | string | Session the event belongs to | use for session-level funnel work; the headline analysis stays user-level on purpose |
| `device_type` | string | Device for this event | `Desktop`, `Mobile`, `Tablet` |
| `order_value` | float | Order value on purchase events; 0 / empty on non-purchase events | |

## Derived metrics (computed in SQL / notebook, stored in `reports/`)

| Metric | Formula | Where |
|---|---|---|
| Conversion rate | `AVG(converted)` per group | `reports/group_kpi_summary.csv` |
| Absolute lift | treatment conversion − control conversion | `reports/primary_conversion_readout.csv` |
| Relative lift | absolute lift / control conversion | `reports/primary_conversion_readout.csv` |
| Revenue per assigned user | `AVG(revenue)` per group — denominator is **all assigned users**, not buyers | `reports/revenue_summary.csv` |
| Funnel reach | users reaching a stage / assigned users, per group | `reports/funnel_reach.csv` |
| Stage conversion | users reaching stage *n+1* / users reaching stage *n* | `reports/stage_conversion.csv` |
| Revenue significance | Welch's t-test, Mann-Whitney U, 95% CI, Cohen's d on `revenue` and `purchase_count` | `reports/revenue_significance.csv` (notebook §9.1, `src/stats_tests.py`) |
