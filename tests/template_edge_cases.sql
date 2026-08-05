-- Edge case templates (candidate should fill these in)

-- Duplicate events should not double-count
-- Out-of-order events should still result in correct totals
-- Partial captures should sum correctly
-- Partial refunds should sum correctly (including refunds on a later day than the capture)
-- Disputes should count once per disputed payment (any non-empty dispute_status)
-- Fraud signals should count per merchant

-- Example:
-- SELECT COUNT(*) FROM payment_events WHERE id = 'evt_2_dup';
