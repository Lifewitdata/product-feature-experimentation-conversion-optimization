# Experiment Design — One-Tap Checkout A/B Test

**Experiment ID:** `EXP_CHECKOUT_2026_01`
**Status:** Completed — readout in `notebooks/product_feature_experimentation.ipynb`, launch deck in `One_Tap_Checkout_AB_Test_Launch_Deck.pptx`
**Run window:** 1–28 July 2026 (28 days)
**Data disclosure:** synthetic dataset; the design below is written the way the experiment would be pre-registered for a real launch, and every number in the readout is computed from the data in `data/`.

---

## 1. Business question

Does replacing the standard multi-step checkout with a **one-tap checkout** increase purchase conversion, without degrading payment success or increasing support load?

## 2. Hypothesis

> **H1:** Users exposed to one-tap checkout (`one_tap_checkout`) will convert at a higher rate than users on the standard checkout (`standard_checkout`), because each removed step removes a drop-off point in the funnel.
>
> **H0:** Conversion is identical in both groups; any observed difference is sampling noise.

Directional expectation, fixed before the readout: the effect, if real, appears first at *checkout start → payment attempt* and carries through to purchase — not in basket size.

## 3. Variants

| Group | `experiment_group` | `feature_variant` | Experience |
|---|---|---|---|
| Control | `control` | `standard_checkout` | Current multi-step checkout |
| Treatment | `treatment` | `one_tap_checkout` | One-tap checkout (saved details, single confirmation) |

## 4. Randomisation and unit of analysis

- **Unit of randomisation:** user (`user_id`), assigned once — no user appears in both groups (verified: 50,000 unique users in assignments, exactly one row per user).
- **Split:** 50/50 target. Observed: 24,904 control / 25,096 treatment.
- **Unit of analysis:** user level throughout. Session- or event-level analysis would double-count repeat visitors and inflate significance, so all primary metrics are computed per assigned user.
- **Validity check (SRM):** Sample Ratio Mismatch chi-square test against the expected 50/50 split — chi-square = 0.737, **p = 0.3905**. No mismatch; the assignment mechanism is trusted.

## 5. Metrics — fixed before the readout

### Primary metric (the launch decision rides on this one)

| Metric | Definition |
|---|---|
| Purchase conversion | `converted` users / all assigned users, per group |

### Secondary metrics (explain *how* the primary moved)

| Metric | Definition |
|---|---|
| Checkout start rate | Users with `checkout_started = 1` / assigned users |
| Payment attempt rate | Users with `payment_attempted = 1` / assigned users |
| Stage conversion | checkout → payment attempt, payment attempt → completed |
| Revenue per assigned user | Mean of `revenue` across **all** assigned users (buyers and non-buyers) |
| Purchases per user | Mean of `purchase_count` |

### Guardrail metrics (must not get materially worse)

| Metric | Threshold set in advance |
|---|---|
| Payment failure rate | No increase beyond +0.5 pp |
| Support contact rate | No increase beyond +0.5 pp |

## 6. Power and sample size

Baseline conversion from pre-experiment traffic: **33.7%**. Two-sided alpha = 0.05, target power = 0.80 (two-proportion test, normal approximation — the same method coded in `src/stats_tests.py`).

| Planning quantity | Value |
|---|---|
| Users needed per arm to detect **+2.0 pp** | **8,891** |
| Users actually run per arm | ~25,000 (24,904 / 25,096) |
| Minimum detectable effect at the run sample size (80% power) | **1.19 pp** |
| Observed effect | +5.26 pp — roughly 4.4× the MDE |
| Achieved power for the observed effect | ≈ 1.000 |

Read: the experiment was comfortably over-powered for any commercially meaningful effect. A null result at this sample size would have been a trustworthy "no effect," not an under-powered miss.

## 7. Analysis plan (as executed)

1. **Data quality first** (`sql/01_data_quality.sql`, notebook section 3): row counts, one row per user per table, no cross-group contamination, zero nulls in `users` / `experiment_metrics`.
2. **SRM check** before any outcome is looked at (`sql/06_srm_check.sql`).
3. **Primary test:** chi-square test of independence on converted × group, with the difference in proportions and a 95% confidence interval (notebook section 5, `src/stats_tests.py::proportion_test`).
4. **Continuous metrics:** revenue per user and purchases per user are **zero-inflated** (61–66% of users have zero revenue — they are the non-converters), so the mean comparison is reported three ways in notebook section 9.1 and `reports/revenue_significance.csv`:
   - **Welch's t-test** (unequal variances) on the mean difference, with a 95% CI;
   - **Mann-Whitney U** as a distribution-free check that does not assume normality;
   - **Cohen's d** so practical significance is stated next to statistical significance.
   A buyers-only cut is also reported, to separate "more buyers" from "bigger baskets."
5. **Funnel and segments** (`sql/03`, `sql/04`): pre-declared cuts only — device, customer segment, country, age group. Segment results are treated as descriptive (no multiplicity correction; no launch decision is taken on a segment alone).
6. **Guardrails** compared against the thresholds in section 5 before any launch recommendation is written.

## 8. Decision rule — fixed before the readout

**Launch** if all three hold:

1. Primary metric is positive and its 95% CI excludes zero;
2. Both guardrails stay inside their +0.5 pp thresholds;
3. No pre-declared segment shows a materially negative effect.

**Result against the rule:** conversion +5.26 pp, 95% CI [+4.42, +6.11] pp, chi-square p = 2.17e-34 ✓ · payment failures −0.01 pp, support contacts +0.14 pp ✓ · all device / customer / country segments positive ✓ → **LAUNCH**. Full numbers: README summary table and `reports/primary_conversion_readout.csv`.

## 9. Known limitations

- Synthetic data with a deliberately embedded treatment effect — this demonstrates method, not a real product claim.
- No novelty / primacy-effect window analysis: the 28-day run is read as a whole. A real rollout would re-check the effect in week 1 vs weeks 3–4.
- Revenue is right-skewed and zero-inflated; the t-test is valid at this sample size (CLT, n ≈ 25k per arm) but the Mann-Whitney result is the one to quote if challenged.
- Segment cuts are exploratory in spirit even though pre-declared in dimensions; effect *sizes* per segment should not be over-interpreted.
