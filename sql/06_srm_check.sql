-- 06_srm_check.sql
-- Purpose : Sample Ratio Mismatch (SRM) check. Compares the observed group
--           split with the designed 50/50 split and computes the chi-square
--           statistic in SQL. Run this BEFORE trusting any outcome metric.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset`.
-- Result on the shipped data: chi-square = 0.737 -> p = 0.3905 (no mismatch).
-- BigQuery has no built-in chi-square CDF, so the p-value itself is computed in
-- Python (notebook section 3 / src/stats_tests.py::srm_check) from this statistic.

WITH observed AS (
  SELECT
    experiment_group,
    COUNT(DISTINCT user_id) AS observed_users
  FROM `project.dataset.experiment_assignments`
  GROUP BY experiment_group
),
totals AS (
  SELECT SUM(observed_users) AS total_users, COUNT(*) AS n_groups FROM observed
)
SELECT
  o.experiment_group,
  o.observed_users,
  t.total_users / t.n_groups AS expected_users,
  o.observed_users - t.total_users / t.n_groups AS deviation,
  POW(o.observed_users - t.total_users / t.n_groups, 2) / (t.total_users / t.n_groups)
    AS chi_square_component
FROM observed AS o
CROSS JOIN totals AS t
ORDER BY o.experiment_group;

-- The test statistic itself (SUM of the components above; df = groups - 1 = 1)
WITH observed AS (
  SELECT COUNT(DISTINCT user_id) AS observed_users
  FROM `project.dataset.experiment_assignments`
  GROUP BY experiment_group
),
totals AS (
  SELECT SUM(observed_users) AS total_users, COUNT(*) AS n_groups FROM observed
)
SELECT
  SUM(POW(observed_users - total_users / n_groups, 2) / (total_users / n_groups)) AS chi_square_statistic,
  ANY_VALUE(n_groups) - 1 AS degrees_of_freedom
FROM observed
CROSS JOIN totals
GROUP BY total_users, n_groups;
