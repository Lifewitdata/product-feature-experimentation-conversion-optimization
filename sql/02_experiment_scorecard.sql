SELECT experiment_group, COUNT(DISTINCT user_id) AS assigned_users,
 AVG(checkout_started) AS checkout_start_rate,
 AVG(payment_attempted) AS payment_attempt_rate,
 AVG(converted) AS purchase_conversion_rate,
 AVG(revenue) AS revenue_per_assigned_user,
 AVG(payment_failure) AS payment_failure_rate,
 AVG(support_contact) AS support_contact_rate
FROM `project.dataset.experiment_metrics`
GROUP BY experiment_group;
