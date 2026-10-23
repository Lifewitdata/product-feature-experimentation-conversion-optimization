-- 05_event_summary.sql
-- Purpose : Event-level behaviour summary from product_events - volume, reach,
--           treatment-only feature exposure, and the daily trend used to spot
--           instrumentation breaks mid-experiment.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset`.

-- Volume and reach per event
SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(DISTINCT session_id) AS sessions,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS share_of_all_events
FROM `project.dataset.product_events`
GROUP BY event_name
ORDER BY event_count DESC;

-- Treatment-only feature exposure: how many assigned treatment users actually
-- saw / used the one-tap feature (exposure validation for the readout)
SELECT
  COUNT(DISTINCT e.user_id) AS treatment_users_exposed
FROM `project.dataset.product_events` AS e
JOIN `project.dataset.experiment_assignments` AS a USING (user_id)
WHERE a.experiment_group = 'treatment'
  AND e.event_name IN ('one_tap_feature_view', 'feature_clicked');

-- Daily event trend across the run window (instrumentation / outage check)
SELECT
  DATE(event_timestamp) AS event_date,
  COUNT(*) AS events,
  COUNT(DISTINCT user_id) AS active_users
FROM `project.dataset.product_events`
GROUP BY event_date
ORDER BY event_date;
