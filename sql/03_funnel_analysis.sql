SELECT experiment_group,
 COUNT(DISTINCT user_id) AS assigned_users,
 SUM(checkout_started) AS checkout_users,
 SUM(payment_attempted) AS payment_attempt_users,
 SUM(payment_completed) AS completed_users,
 SAFE_DIVIDE(SUM(payment_attempted),SUM(checkout_started)) AS checkout_to_attempt_rate,
 SAFE_DIVIDE(SUM(payment_completed),SUM(payment_attempted)) AS attempt_to_complete_rate
FROM `project.dataset.experiment_metrics`
GROUP BY experiment_group;
