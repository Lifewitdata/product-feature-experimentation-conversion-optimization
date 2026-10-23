-- 02_experiment_scorecard.sql
-- Purpose : The user-level KPI scorecard for the readout, plus the lift block
--           (absolute lift, relative lift) computed in SQL.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset`.
-- Grain   : one row per experiment group. Analysis is user-level throughout so
--           repeat sessions cannot inflate conversion.

WITH group_kpis AS (
  SELECT
    experiment_group,
    COUNT(DISTINCT user_id) AS assigned_users,
    AVG(checkout_started)   AS checkout_start_rate,
    AVG(payment_attempted)  AS payment_attempt_rate,
    AVG(payment_completed)  AS payment_completion_rate,
    AVG(converted)          AS conversion_rate,
    AVG(revenue)            AS revenue_per_assigned_user,
    SUM(revenue)            AS total_revenue,
    AVG(purchase_count)     AS purchases_per_user,
    AVG(payment_failure)    AS payment_failure_rate,   -- guardrail
    AVG(support_contact)    AS support_contact_rate    -- guardrail
  FROM `project.dataset.experiment_metrics`
  GROUP BY experiment_group
)
SELECT *
FROM group_kpis
ORDER BY experiment_group;

-- Lift block: one row, control vs treatment side by side.
-- (Significance test for this difference - chi-square + 95% CI - lives in the
--  notebook, section 5, and in src/stats_tests.py; see also 06_srm_check.sql.)
WITH group_kpis AS (
  SELECT
    experiment_group,
    AVG(converted) AS conversion_rate,
    AVG(revenue)   AS revenue_per_assigned_user,
    AVG(payment_failure) AS payment_failure_rate,
    AVG(support_contact) AS support_contact_rate
  FROM `project.dataset.experiment_metrics`
  GROUP BY experiment_group
),
pivoted AS (
  SELECT
    MAX(IF(experiment_group = 'control',   conversion_rate, NULL)) AS control_conversion,
    MAX(IF(experiment_group = 'treatment', conversion_rate, NULL)) AS treatment_conversion,
    MAX(IF(experiment_group = 'control',   revenue_per_assigned_user, NULL)) AS control_rev_per_user,
    MAX(IF(experiment_group = 'treatment', revenue_per_assigned_user, NULL)) AS treatment_rev_per_user,
    MAX(IF(experiment_group = 'treatment', payment_failure_rate, NULL))
      - MAX(IF(experiment_group = 'control', payment_failure_rate, NULL)) AS payment_failure_diff_pp,
    MAX(IF(experiment_group = 'treatment', support_contact_rate, NULL))
      - MAX(IF(experiment_group = 'control', support_contact_rate, NULL)) AS support_contact_diff_pp
  FROM group_kpis
)
SELECT
  control_conversion,
  treatment_conversion,
  treatment_conversion - control_conversion               AS absolute_lift,
  (treatment_conversion - control_conversion) / control_conversion AS relative_lift,
  control_rev_per_user,
  treatment_rev_per_user,
  treatment_rev_per_user - control_rev_per_user           AS revenue_per_user_diff,
  payment_failure_diff_pp,                                 -- guardrail, must stay <= +0.005
  support_contact_diff_pp                                  -- guardrail, must stay <= +0.005
FROM pivoted;
