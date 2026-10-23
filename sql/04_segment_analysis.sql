-- 04_segment_analysis.sql
-- Purpose : Pre-declared segment cuts (device, customer segment, country, age
--           group) with the conversion lift computed per segment in SQL.
--           Segments are descriptive: no launch decision is taken on one alone.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset`.

-- Device x customer segment detail (the original deep cut)
SELECT
  u.device_type,
  u.customer_segment,
  m.experiment_group,
  COUNT(DISTINCT m.user_id) AS users,
  AVG(m.converted) AS conversion_rate,
  AVG(m.revenue)   AS revenue_per_user
FROM `project.dataset.experiment_metrics` AS m
JOIN `project.dataset.users` AS u USING (user_id)
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- Lift by device
WITH seg AS (
  SELECT u.device_type AS segment,
         m.experiment_group,
         AVG(m.converted) AS conversion_rate,
         COUNT(*) AS users
  FROM `project.dataset.experiment_metrics` AS m
  JOIN `project.dataset.users` AS u USING (user_id)
  GROUP BY 1, 2
)
SELECT
  segment,
  SUM(IF(experiment_group = 'control', users, 0))   AS control_users,
  SUM(IF(experiment_group = 'treatment', users, 0)) AS treatment_users,
  MAX(IF(experiment_group = 'control', conversion_rate, NULL))   AS control_conversion,
  MAX(IF(experiment_group = 'treatment', conversion_rate, NULL)) AS treatment_conversion,
  MAX(IF(experiment_group = 'treatment', conversion_rate, NULL))
    - MAX(IF(experiment_group = 'control', conversion_rate, NULL)) AS absolute_lift
FROM seg
GROUP BY segment
ORDER BY absolute_lift DESC;

-- Lift by customer segment (same shape; swap the segment column to re-use for
-- country or age_group)
WITH seg AS (
  SELECT u.customer_segment AS segment,
         m.experiment_group,
         AVG(m.converted) AS conversion_rate,
         COUNT(*) AS users
  FROM `project.dataset.experiment_metrics` AS m
  JOIN `project.dataset.users` AS u USING (user_id)
  GROUP BY 1, 2
)
SELECT
  segment,
  SUM(IF(experiment_group = 'control', users, 0))   AS control_users,
  SUM(IF(experiment_group = 'treatment', users, 0)) AS treatment_users,
  MAX(IF(experiment_group = 'control', conversion_rate, NULL))   AS control_conversion,
  MAX(IF(experiment_group = 'treatment', conversion_rate, NULL)) AS treatment_conversion,
  MAX(IF(experiment_group = 'treatment', conversion_rate, NULL))
    - MAX(IF(experiment_group = 'control', conversion_rate, NULL)) AS absolute_lift
FROM seg
GROUP BY segment
ORDER BY absolute_lift DESC;
