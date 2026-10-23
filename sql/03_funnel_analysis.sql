-- 03_funnel_analysis.sql
-- Purpose : Funnel reach (share of ALL assigned users reaching each stage) and
--           stage-to-stage conversion, per group. Shows WHERE the lift enters.
-- Dialect : BigQuery Standard SQL. Replace `project.dataset`.

WITH funnel AS (
  SELECT
    experiment_group,
    COUNT(DISTINCT user_id) AS assigned_users,
    SUM(checkout_started)   AS checkout_users,
    SUM(payment_attempted)  AS payment_attempt_users,
    SUM(payment_completed)  AS completed_users
  FROM `project.dataset.experiment_metrics`
  GROUP BY experiment_group
)
SELECT
  experiment_group,
  assigned_users,
  -- Reach: denominator is every assigned user, not the previous stage
  SAFE_DIVIDE(checkout_users, assigned_users)        AS checkout_start_reach,
  SAFE_DIVIDE(payment_attempt_users, assigned_users) AS payment_attempt_reach,
  SAFE_DIVIDE(completed_users, assigned_users)       AS purchase_reach,
  -- Stage conversion: denominator is the previous stage
  SAFE_DIVIDE(payment_attempt_users, checkout_users) AS checkout_to_attempt_rate,
  SAFE_DIVIDE(completed_users, payment_attempt_users) AS attempt_to_complete_rate,
  -- Biggest single drop-off in this group's funnel
  1 - SAFE_DIVIDE(payment_attempt_users, checkout_users) AS checkout_dropoff_rate,
  1 - SAFE_DIVIDE(completed_users, payment_attempt_users) AS payment_dropoff_rate
FROM funnel
ORDER BY experiment_group;

-- Event-level cross-check from product_events: sessions reaching each stage.
-- This is a validation view only - the headline funnel above stays user-level.
SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(DISTINCT session_id) AS sessions
FROM `project.dataset.product_events`
WHERE event_name IN ('checkout_started', 'payment_attempted', 'purchase_completed')
GROUP BY event_name
ORDER BY event_count DESC;
