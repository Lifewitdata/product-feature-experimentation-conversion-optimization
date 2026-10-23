"""User-level metric definitions for the one-tap checkout experiment.

One place where every headline metric is defined, so the notebook, the
SQL in ``sql/`` and the dashboard cannot drift apart. All metrics are
computed per *assigned user* - never per session - so repeat visits
cannot inflate conversion.
"""

from __future__ import annotations

import pandas as pd

GROUP = "experiment_group"
FUNNEL_STAGES = ["checkout_started", "payment_attempted", "payment_completed"]
GUARDRAILS = ["payment_failure", "support_contact"]


def group_scorecard(metrics: pd.DataFrame) -> pd.DataFrame:
    """KPI scorecard: one row per experiment group (mirrors sql/02)."""
    return metrics.groupby(GROUP).agg(
        assigned_users=("user_id", "nunique"),
        checkout_start_rate=("checkout_started", "mean"),
        payment_attempt_rate=("payment_attempted", "mean"),
        conversion_rate=("converted", "mean"),
        revenue_per_assigned_user=("revenue", "mean"),
        total_revenue=("revenue", "sum"),
        purchases_per_user=("purchase_count", "mean"),
        payment_failure_rate=("payment_failure", "mean"),
        support_contact_rate=("support_contact", "mean"),
    ).reset_index()


def funnel_reach(metrics: pd.DataFrame) -> pd.DataFrame:
    """Share of all assigned users reaching each funnel stage, per group."""
    out = metrics.groupby(GROUP)[FUNNEL_STAGES].mean().reset_index()
    return out.rename(columns={
        "checkout_started": "checkout_started",
        "payment_attempted": "payment_attempted",
        "payment_completed": "payment_completed",
    })


def buyers_only(metrics: pd.DataFrame) -> pd.DataFrame:
    """Revenue per *buyer* - separates 'more buyers' from 'bigger baskets'."""
    buyers = metrics[metrics["converted"] == 1]
    return buyers.groupby(GROUP).agg(
        buyers=("user_id", "count"),
        revenue_per_buyer=("revenue", "mean"),
        sd_revenue_per_buyer=("revenue", "std"),
    ).reset_index()
