-- BigQuery Standard SQL; replace project.dataset.
SELECT 'users' AS table_name, COUNT(*) AS rows, COUNT(DISTINCT user_id) AS unique_users FROM `project.dataset.users`
UNION ALL SELECT 'assignments', COUNT(*), COUNT(DISTINCT user_id) FROM `project.dataset.experiment_assignments`
UNION ALL SELECT 'metrics', COUNT(*), COUNT(DISTINCT user_id) FROM `project.dataset.experiment_metrics`;

SELECT experiment_group, COUNT(DISTINCT user_id) AS users
FROM `project.dataset.experiment_assignments` GROUP BY 1;
