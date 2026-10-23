-- 07_revenue_significance.sql
-- Purpose : The ingredients of the Welch two-sample t-test for revenue per
--           assigned user, computed in SQL: group n, mean, variance, the
--           standard error of the difference and the t-statistic itself.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset`.
-- Note    : BigQuery does not ship a t-distribution CDF, so the p-value and
--           confidence interval are finished in Python (notebook section 9.1 /
--           reports/revenue_significance.csv). On the shipped data this query
--           returns t = 8.08, and Python reports p = 6.7e-16 with a 95% CI for
--           the difference of [+1.84, +3.03] dollars per user.

WITH group_stats AS (
  SELECT
    experiment_group,
    COUNT(*) AS n_users,
    AVG(revenue) AS mean_revenue_per_user,
    VAR_SAMP(revenue) AS var_revenue,
    STDDEV_SAMP(revenue) AS sd_revenue,
    AVG(purchase_count) AS mean_purchases_per_user,
    VAR_SAMP(purchase_count) AS var_purchases
  FROM `project.dataset.experiment_metrics`
  GROUP BY experiment_group
),
pivoted AS (
  SELECT
    MAX(IF(experiment_group = 'control', n_users, NULL)) AS n_control,
    MAX(IF(experiment_group = 'treatment', n_users, NULL)) AS n_treatment,
    MAX(IF(experiment_group = 'control', mean_revenue_per_user, NULL)) AS mean_control,
    MAX(IF(experiment_group = 'treatment', mean_revenue_per_user, NULL)) AS mean_treatment,
    MAX(IF(experiment_group = 'control', var_revenue, NULL)) AS var_control,
    MAX(IF(experiment_group = 'treatment', var_revenue, NULL)) AS var_treatment
  FROM group_stats
)
SELECT
  mean_control,
  mean_treatment,
  mean_treatment - mean_control AS mean_difference,
  SQRT(var_treatment / n_treatment + var_control / n_control) AS standard_error,
  (mean_treatment - mean_control)
    / SQRT(var_treatment / n_treatment + var_control / n_control) AS welch_t_statistic
FROM pivoted;

-- Buyers-only cut: is a completed basket worth more under one-tap checkout,
-- or does the revenue lift come purely from MORE buyers converting?
-- (Shipped data: $49.41 control vs $48.99 treatment, Welch p = 0.47 - the lift
--  is more buyers, not bigger baskets.)
SELECT
  experiment_group,
  COUNT(*) AS buyers,
  AVG(revenue) AS revenue_per_buyer,
  STDDEV_SAMP(revenue) AS sd_revenue_per_buyer
FROM `project.dataset.experiment_metrics`
WHERE converted = 1
GROUP BY experiment_group
ORDER BY experiment_group;
