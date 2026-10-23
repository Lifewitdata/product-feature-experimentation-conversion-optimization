# Product Feature Experimentation & Conversion Optimization
## Product Analytics Case Study — One-Tap Checkout A/B Test

**Data disclosure:** All records and outcomes are synthetic. The simulated treatment effect is intentionally embedded in the data-generation process; this is not evidence about a real product.

### Business question
Does a one-tap checkout feature improve purchase conversion, where does user progression change, and are guardrails such as payment failures and support contacts affected?

### Headline results

| Metric | Control | Treatment | Difference |
|---|---|---|---|
| Assigned users | 24,904 | 25,096 | 50,000 total |
| Purchase conversion | 33.70% | 38.96% | **+5.26 pp (+15.6% relative)**, 95% CI [+4.42, +6.11] pp, chi-square p = 2.17e-34 |
| Revenue per assigned user | $16.65 | $19.09 | **+$2.44**, 95% CI [+1.84, +3.03], Welch's t-test p = 6.7e-16 |
| Payment failure rate (guardrail) | 3.71% | 3.71% | −0.01 pp |
| Support contact rate (guardrail) | 3.49% | 3.63% | +0.14 pp |
| Sample Ratio Mismatch check | — | — | chi-square = 0.74, p = 0.39 (no mismatch) |

**Verdict: LAUNCH.** The revenue lift is driven by more buyers converting, not bigger baskets — revenue per *buyer* is unchanged ($49.41 vs $48.99, p = 0.47). Effect sizes, funnel detail and segment cuts are in `reports/`; the senior-management readout is the slide deck below.

### Presentation
`One_Tap_Checkout_AB_Test_Launch_Deck.pptx` — 8-slide launch deck: the experiment, how success was measured, headline result, funnel, revenue, guardrails and segments, and the launch recommendation with a post-launch monitoring plan.

### Documentation
- `docs/experiment_design.md` — hypothesis, variants, randomisation, metric definitions, guardrail thresholds, power / sample-size (MDE 1.19 pp at the run size), analysis plan and the pre-set launch decision rule.
- `docs/data_dictionary.md` — every column of every data file, plus how each derived metric in `reports/` is calculated.

### Dataset scale
- 50,000 user profiles
- 50,000 randomized assignments
- 50,000 user-level outcome records
- 293,364 product event records

### Repository
```text
product-feature-experimentation/
├── data/                  # four synthetic CSVs (see docs/data_dictionary.md)
├── notebooks/             # analyst-style end-to-end notebook (31 cells, executed)
├── sql/                   # BigQuery Standard SQL: quality, scorecard, funnel,
│                          # segments, events, SRM check, revenue significance
├── src/                   # reusable metric + statistical-test functions
│                          # (python -m src.run_analysis regenerates the revenue readout)
├── docs/                  # experiment design + data dictionary
├── dashboard/             # Streamlit scorecard + its tests
├── reports/               # generated summary CSVs, incl. revenue_significance.csv
├── One_Tap_Checkout_AB_Test_Launch_Deck.pptx   # senior-management slide deck
├── README.md
└── requirements.txt
```

### Run
```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
jupyter notebook
```
Open `notebooks/product_feature_experimentation.ipynb` and run all cells from top to bottom.

### Dashboard
`dashboard/streamlit_app.py` renders the readout as a Streamlit app. It reads the
generated CSVs in `reports/` rather than repeating the analysis, so it stays in
step with whatever the notebook last wrote.

```bash
streamlit run dashboard/streamlit_app.py
python -m pytest dashboard/test_app.py -q   # 5 headless AppTest checks
```

Shows the four headline figures (control 33.70%, treatment 38.96%, absolute lift
+5.26 pp, chi-square p-value 2.17e-34), the 95% CI for the lift, funnel reach as
a chart or a table, the two guardrails, and the group KPI scorecard.

Note on `difference_pp`: `reports/guardrail_summary.csv` already stores that
column in percentage points while `control` and `treatment` are proportions. A
blanket percent format over all three columns inflates the difference by 100x —
`-0.008 pp` displays as `-0.849%`. The dashboard scales only the two proportion
columns and leaves `difference_pp` alone.

### Main analysis
Data quality and grain validation; sample-ratio mismatch diagnostic; user-level KPI scorecard; conversion difference with 95% confidence interval and chi-square test; **Welch's t-test and Mann-Whitney U for revenue per user (notebook section 9.1), with Cohen's d and a buyers-only cut**; funnel reach and stage conversion; guardrail metrics; segment cuts; revenue and event analysis; dashboard-ready exports.

### Metric definitions
- Conversion = converted assigned users / all assigned users.
- Absolute lift = treatment conversion − control conversion.
- Relative lift = absolute lift / control conversion.
- Revenue per assigned user = total revenue / assigned users.
- Funnel reach = users reaching stage / all assigned users.

### SQL
Replace `project.dataset` with your BigQuery identifiers. The seven files run in order: `01_data_quality` (grain, contamination, null and flag checks), `02_experiment_scorecard` (KPIs + lift), `03_funnel_analysis`, `04_segment_analysis`, `05_event_summary`, `06_srm_check` (SRM chi-square statistic), `07_revenue_significance` (the Welch t-test ingredients and the buyers-only cut in SQL).

### Important limitations
This is synthetic data with a deliberately simulated effect. It is designed to demonstrate workflow and communication, not to make a real-world causal claim. A real experiment needs pre-defined metrics, power analysis, exposure validation, guardrail thresholds, monitoring, and careful treatment of exploratory subgroup analysis — the design document in `docs/` shows how each of those is handled here.
