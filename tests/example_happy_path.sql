-- Candidate can use this to validate the base (happy path) data,
-- BEFORE loading any starter edge-case CSVs.
--
-- Expected output on the base data alone:
--   merchant_id | report_date | total_authorized_amount | total_captured_amount | total_refunded_amount
--   A           | 2026-01-01  |                     100 |                   100 |                     0
--   B           | 2026-01-01  |                     200 |                   200 |                     0
--
-- Note: this naive aggregation is NOT a correct pipeline — once the starter
-- edge-case data is loaded it will produce wrong numbers. Handling that is
-- your task.

SELECT
  merchant_id,
  created_at::date AS report_date,
  SUM(CASE WHEN event_type = 'AUTHORIZED' THEN amount ELSE 0 END) AS total_authorized_amount,
  SUM(CASE WHEN event_type = 'CAPTURED'   THEN amount ELSE 0 END) AS total_captured_amount,
  SUM(CASE WHEN event_type = 'REFUNDED'   THEN amount ELSE 0 END) AS total_refunded_amount
FROM payment_events
GROUP BY merchant_id, created_at::date
ORDER BY merchant_id, report_date;
