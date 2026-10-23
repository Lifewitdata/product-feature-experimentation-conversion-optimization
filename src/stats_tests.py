"""Statistical tests for the one-tap checkout A/B experiment.

Every test used in the notebook readout lives here as a small, named,
reusable function, so the notebook, the SQL and this module all report
the same numbers from the same definitions:

- ``proportion_test``   - chi-square test + difference in proportions with a
                          95% CI (primary metric: purchase conversion).
- ``srm_check``         - Sample Ratio Mismatch chi-square against the
                          designed split.
- ``continuous_test``   - Welch's t-test + Mann-Whitney U + Cohen's d for
                          continuous, zero-inflated metrics (revenue per
                          user, purchases per user).
- ``required_sample_size`` / ``minimum_detectable_effect`` - the power
                          planning numbers quoted in docs/experiment_design.md.

Run ``python -m src.run_analysis`` from the repo root to regenerate
``reports/revenue_significance.csv``.
"""

from __future__ import annotations

import numpy as np
from scipy import stats


def proportion_test(control_success: int, control_n: int,
                    treatment_success: int, treatment_n: int,
                    alpha: float = 0.05) -> dict:
    """Chi-square test on a 2x2 conversion table + CI for the difference."""
    p_c = control_success / control_n
    p_t = treatment_success / treatment_n
    diff = p_t - p_c
    se = np.sqrt(p_c * (1 - p_c) / control_n + p_t * (1 - p_t) / treatment_n)
    z = stats.norm.ppf(1 - alpha / 2)
    table = [[control_success, control_n - control_success],
             [treatment_success, treatment_n - treatment_success]]
    chi2, p_value, _, _ = stats.chi2_contingency(table, correction=False)
    return {
        "control_rate": p_c,
        "treatment_rate": p_t,
        "absolute_lift_pp": diff * 100,
        "relative_lift_pct": diff / p_c * 100,
        "ci_95_low_pp": (diff - z * se) * 100,
        "ci_95_high_pp": (diff + z * se) * 100,
        "chi_square": chi2,
        "p_value": p_value,
    }


def srm_check(observed_counts: list[int], expected_ratio: list[float] | None = None) -> dict:
    """Sample Ratio Mismatch check against the designed assignment ratio."""
    observed = np.asarray(observed_counts, dtype=float)
    ratio = np.asarray(expected_ratio or [1.0] * len(observed), dtype=float)
    expected = observed.sum() * ratio / ratio.sum()
    chi2 = float(((observed - expected) ** 2 / expected).sum())
    df = len(observed) - 1
    return {"chi_square": chi2, "df": df, "p_value": float(1 - stats.chi2.cdf(chi2, df))}


def continuous_test(control: np.ndarray, treatment: np.ndarray,
                    alpha: float = 0.05) -> dict:
    """Welch's t-test + Mann-Whitney U + effect size for a continuous metric.

    Revenue per user is zero-inflated (non-buyers are exactly 0), so the
    t-test (valid at this n by the CLT) is always reported next to the
    distribution-free Mann-Whitney result and Cohen's d.
    """
    a = np.asarray(control, dtype=float)
    b = np.asarray(treatment, dtype=float)
    t_test = stats.ttest_ind(b, a, equal_var=False)
    mwu = stats.mannwhitneyu(b, a, alternative="two-sided")
    diff = b.mean() - a.mean()
    se = np.sqrt(a.var(ddof=1) / len(a) + b.var(ddof=1) / len(b))
    df_num = (a.var(ddof=1) / len(a) + b.var(ddof=1) / len(b)) ** 2
    df_den = ((a.var(ddof=1) / len(a)) ** 2 / (len(a) - 1)
              + (b.var(ddof=1) / len(b)) ** 2 / (len(b) - 1))
    df = df_num / df_den
    crit = stats.t.ppf(1 - alpha / 2, df)
    pooled_sd = np.sqrt(((len(a) - 1) * a.var(ddof=1) + (len(b) - 1) * b.var(ddof=1))
                        / (len(a) + len(b) - 2))
    return {
        "control_mean": a.mean(),
        "treatment_mean": b.mean(),
        "difference": diff,
        "ci_95_low": diff - crit * se,
        "ci_95_high": diff + crit * se,
        "welch_t": float(t_test.statistic),
        "welch_df": float(df),
        "welch_p": float(t_test.pvalue),
        "mann_whitney_u": float(mwu.statistic),
        "mann_whitney_p": float(mwu.pvalue),
        "cohens_d": diff / pooled_sd,
    }


def _cohens_h(p1: float, p2: float) -> float:
    return 2 * np.arcsin(np.sqrt(p2)) - 2 * np.arcsin(np.sqrt(p1))


def required_sample_size(baseline_rate: float, mde_pp: float,
                         alpha: float = 0.05, power: float = 0.80) -> float:
    """Users per arm to detect an absolute lift of ``mde_pp`` points."""
    from statsmodels.stats.power import NormalIndPower
    effect = _cohens_h(baseline_rate, baseline_rate + mde_pp / 100)
    return float(NormalIndPower().solve_power(effect_size=effect, alpha=alpha, power=power))


def minimum_detectable_effect(baseline_rate: float, n_per_arm: int,
                              alpha: float = 0.05, power: float = 0.80) -> float:
    """Smallest absolute lift (in percentage points) detectable at ``n_per_arm``."""
    from scipy.optimize import brentq
    from statsmodels.stats.power import NormalIndPower

    def gap(p2: float) -> float:
        return NormalIndPower().power(
            effect_size=_cohens_h(baseline_rate, p2), nobs1=n_per_arm, alpha=alpha) - power

    return float((brentq(gap, baseline_rate + 1e-4, 0.99) - baseline_rate) * 100)
