"""Regenerate reports/revenue_significance.csv from the raw metrics table.

Usage (from the repo root):

    python -m src.run_analysis

Writes one row per continuous metric with the Welch t-test, Mann-Whitney U,
95% CI and Cohen's d reported in notebook section 9.1.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from src.stats_tests import continuous_test

ROOT = Path(__file__).resolve().parents[1]
METRICS_FILE = ROOT / "data" / "experiment_metrics.csv"
OUT_FILE = ROOT / "reports" / "revenue_significance.csv"
CONTINUOUS_METRICS = ["revenue", "purchase_count"]


def main() -> None:
    metrics = pd.read_csv(METRICS_FILE)
    control = metrics[metrics["experiment_group"] == "control"]
    treatment = metrics[metrics["experiment_group"] == "treatment"]

    rows = []
    for column in CONTINUOUS_METRICS:
        result = continuous_test(control[column].to_numpy(), treatment[column].to_numpy())
        rows.append({"metric": column, "control_n": len(control),
                     "treatment_n": len(treatment), **result})

    # Buyers-only revenue: is a basket worth more, or are there just more buyers?
    buyers = metrics[metrics["converted"] == 1]
    result = continuous_test(
        buyers[buyers["experiment_group"] == "control"]["revenue"].to_numpy(),
        buyers[buyers["experiment_group"] == "treatment"]["revenue"].to_numpy())
    rows.append({"metric": "revenue_buyers_only",
                 "control_n": int((buyers["experiment_group"] == "control").sum()),
                 "treatment_n": int((buyers["experiment_group"] == "treatment").sum()),
                 **result})

    report = pd.DataFrame(rows)
    report.to_csv(OUT_FILE, index=False)
    print(f"Wrote {OUT_FILE}")
    print(report.to_string(index=False))


if __name__ == "__main__":
    main()
