SELECT event_name, COUNT(*) AS event_count, COUNT(DISTINCT user_id) AS unique_users
FROM `project.dataset.product_events` GROUP BY event_name ORDER BY event_count DESC;
