# Product Feature Experimentation & Conversion Optimization
## Product Analytics Case Study — One-Tap Checkout A/B Test

**Data disclosure:** All records and outcomes are synthetic. The simulated treatment effect is intentionally embedded in the data-generation process; this is not evidence about a real product.

### Business question
Does a one-tap checkout feature improve purchase conversion, where does user progression change, and are guardrails such as payment failures and support contacts affected?

### Dataset scale
- 50,000 user profiles
- 50,000 randomized assignments
- 50,000 user-level outcome records
- 293,364 product event records

### Repository
```text
product-feature-experimentation/
├── data/                  # four synthetic CSVs
├── notebooks/             # analyst-style end-to-end notebook
├── sql/                   # BigQuery Standard SQL templates
├── dashboard/             # dashboard planning / exports
├── reports/               # generated summary CSVs
├── src/                   # optional reusable scripts
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

### Main analysis
Data quality and grain validation; sample-ratio mismatch diagnostic; user-level KPI scorecard; conversion difference with 95% confidence interval and chi-square test; funnel reach and stage conversion; guardrail metrics; segment cuts; revenue and event analysis; dashboard-ready exports.

### Metric definitions
- Conversion = converted assigned users / all assigned users.
- Absolute lift = treatment conversion − control conversion.
- Relative lift = absolute lift / control conversion.
- Revenue per assigned user = total revenue / assigned users.
- Funnel reach = users reaching stage / all assigned users.

### SQL
Replace `project.dataset` with your BigQuery identifiers.

### Important limitations
This is synthetic data with a deliberately simulated effect. It is designed to demonstrate workflow and communication, not to make a real-world causal claim. A real experiment needs pre-defined metrics, power analysis, exposure validation, guardrail thresholds, monitoring, and careful treatment of exploratory subgroup analysis.
