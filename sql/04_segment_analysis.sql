SELECT u.device_type, u.customer_segment, m.experiment_group,
 COUNT(DISTINCT m.user_id) AS users, AVG(m.converted) AS conversion_rate,
 AVG(m.revenue) AS revenue_per_user
FROM `project.dataset.experiment_metrics` m JOIN `project.dataset.users` u USING(user_id)
GROUP BY 1,2,3 ORDER BY 1,2,3;
