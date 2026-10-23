-- 01_data_quality.sql
-- Purpose : Prove the four source tables are trustworthy BEFORE any KPI is read.
--           Grain checks (one row per user), cross-group contamination, nulls,
--           assignment balance and the experiment window.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset` with your project/dataset.
-- Output  : One row per check; every check is expected to PASS on the shipped data.

-- Check 1 - row counts vs distinct users (grain) for every source table
SELECT
  'grain' AS check_area,
  'users' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT user_id) AS distinct_users,
  COUNT(*) = COUNT(DISTINCT user_id) AS is_one_row_per_user
FROM `project.dataset.users`
UNION ALL
SELECT 'grain', 'experiment_assignments', COUNT(*), COUNT(DISTINCT user_id),
       COUNT(*) = COUNT(DISTINCT user_id)
FROM `project.dataset.experiment_assignments`
UNION ALL
SELECT 'grain', 'experiment_metrics', COUNT(*), COUNT(DISTINCT user_id),
       COUNT(*) = COUNT(DISTINCT user_id)
FROM `project.dataset.experiment_metrics`;

-- Check 2 - no user assigned to more than one experiment group (contamination)
SELECT
  COUNT(*) AS users_in_multiple_groups   -- expected: 0
FROM (
  SELECT user_id
  FROM `project.dataset.experiment_assignments`
  GROUP BY user_id
  HAVING COUNT(DISTINCT experiment_group) > 1
);

-- Check 3 - assignment group in assignments matches the metrics table, user by user
SELECT
  COUNT(*) AS mismatched_users           -- expected: 0
FROM `project.dataset.experiment_assignments` AS a
JOIN `project.dataset.experiment_metrics` AS m USING (user_id)
WHERE a.experiment_group != m.experiment_group;

-- Check 4 - null audit on the analysis table (all expected: 0)
SELECT
  COUNTIF(user_id IS NULL)          AS null_user_id,
  COUNTIF(converted IS NULL)        AS null_converted,
  COUNTIF(revenue IS NULL)          AS null_revenue,
  COUNTIF(payment_failure IS NULL)  AS null_payment_failure,
  COUNTIF(support_contact IS NULL)  AS null_support_contact
FROM `project.dataset.experiment_metrics`;

-- Check 5 - flag sanity: every binary column really is 0/1, and the funnel is monotone
SELECT
  COUNTIF(converted NOT IN (0, 1))                       AS bad_converted_values,
  COUNTIF(payment_completed = 1 AND converted = 0)       AS completed_not_converted,  -- expected: 0
  COUNTIF(payment_attempted = 1 AND checkout_started = 0) AS attempt_without_checkout, -- expected: 0
  COUNTIF(converted = 1 AND payment_attempted = 0)       AS converted_without_attempt   -- expected: 0
FROM `project.dataset.experiment_metrics`;

-- Check 6 - assignment volume by group and the observed experiment window
SELECT
  experiment_group,
  COUNT(DISTINCT user_id) AS assigned_users,
  MIN(assignment_date)    AS first_assignment,
  MAX(assignment_date)    AS last_assignment
FROM `project.dataset.experiment_assignments`
GROUP BY experiment_group
ORDER BY experiment_group;
