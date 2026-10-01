# PRD: Cash Register Session Balances Materialized View

## Overview
Create a materialized view for pre-computed cash register session balances (beginning, ending, cash in, cash out, variance) to accelerate:
- Cash Register Session show/index pages
- Cash Register Session PDF reports
- Employee cash count workflows
- End-of-day reconciliation

## Current Pain Points
- `CashRegisterSession#beginning_balance` and `#ending_balance` query entries and sum amounts in Ruby
- `CashRegisterSessionPdf` iterates entries and computes per-entry cash in/out
- `CashRegisterSessionsController#show` does multiple queries for session totals
- Employee remittance workflow computes balances per session

## Target Implementation

### 1. Cash Register Session Summary MV
```sql
CREATE MATERIALIZED VIEW mv_cash_register_session_summary AS
SELECT
  crs.id AS session_id,
  crs.employee_id,
  crs.cash_account_id,
  crs.store_front_id,
  crs.session_date,
  crs.status,
  crs.opened_at,
  crs.closed_at,
  crs.opening_declared_amount,
  crs.opening_system_amount,
  crs.closing_declared_amount,
  crs.closing_system_amount,
  crs.variance_amount,
  -- Computed from entries
  COALESCE(SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END), 0) AS total_cash_in,
  COALESCE(SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END), 0) AS total_cash_out,
  COALESCE(SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END), 0) -
  COALESCE(SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END), 0) AS net_cash_flow,
  -- System computed opening (from prior session or declared)
  crs.opening_system_amount AS system_opening_balance,
  -- System computed closing = opening + net_flow
  crs.opening_system_amount +
  COALESCE(SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END), 0) -
  COALESCE(SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END), 0) AS system_closing_balance,
  -- Entry count for audit
  COUNT(DISTINCT e.id) AS entry_count
FROM cash_register_sessions crs
LEFT JOIN accounting_module_entries e ON e.cash_register_session_id = crs.id
LEFT JOIN accounting_module_amounts am ON am.entry_id = e.id
LEFT JOIN accounting_module_accounts a ON a.id = am.account_id AND a.id = crs.cash_account_id
GROUP BY crs.id, crs.employee_id, crs.cash_account_id, crs.store_front_id, crs.session_date,
         crs.status, crs.opened_at, crs.closed_at, crs.opening_declared_amount,
         crs.opening_system_amount, crs.closing_declared_amount, crs.closing_system_amount,
         crs.variance_amount;

CREATE UNIQUE INDEX idx_mv_crs_summary_session ON mv_cash_register_session_summary(session_id);
CREATE INDEX idx_mv_crs_summary_employee_date ON mv_cash_register_session_summary(employee_id, session_date);
CREATE INDEX idx_mv_crs_summary_store_date ON mv_cash_register_session_summary(store_front_id, session_date);
CREATE INDEX idx_mv_crs_summary_status ON mv_cash_register_session_summary(status);
```

### 2. Cash Account Daily Flow MV (for cross-session reconciliation)
```sql
CREATE MATERIALIZED VIEW mv_cash_account_daily_flow AS
SELECT
  ca.id AS cash_account_id,
  ca.user_id AS employee_id,
  DATE(e.entry_date) AS flow_date,
  SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END) AS daily_debits,
  SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END) AS daily_credits,
  SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END) -
  SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END) AS net_flow,
  COUNT(DISTINCT e.id) AS entry_count,
  COUNT(DISTINCT e.cash_register_session_id) AS session_count
FROM accounting_module_accounts ca
JOIN accounting_module_amounts am ON am.account_id = ca.id
JOIN accounting_module_entries e ON e.id = am.entry_id
WHERE ca.id IN (SELECT cash_account_id FROM cash_register_sessions WHERE cash_account_id IS NOT NULL)
  AND e.entry_date IS NOT NULL
GROUP BY ca.id, ca.user_id, DATE(e.entry_date);

CREATE INDEX idx_mv_cash_flow_account_date ON mv_cash_account_daily_flow(cash_account_id, flow_date);
```

## Query Patterns Supported

| Use Case | Current | With MV |
|----------|---------|---------|
| Session show page | Multiple queries + Ruby sums | Single row from `mv_cash_register_session_summary` |
| Session PDF report | Iterate entries, sum per entry | Query MV for totals, line items from entries |
| Employee cash count | Compute per session | MV provides pre-computed totals |
| End-of-day reconciliation | Manual computation | `SELECT * FROM mv_cash_register_session_summary WHERE session_date = ?` |
| Cross-session audit | Manual query | `mv_cash_account_daily_flow` for daily totals |

## Refresh Strategy
- **Frequency**: Every 1-2 minutes (critical for cash handling)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY`
- **Trigger**: After entry creation (sales, expenses, remittances), session close
- **Real-time option**: Consider trigger-based update for `total_cash_in/out` columns

## Integration Points
1. **CashRegisterSession Model**: Add `materialized_summary` method
2. **CashRegisterSessionsController**: Use MV for index/show
3. **CashRegisterSessionPdf**: Use MV for summary, entries for detail
4. **Employee Remittances**: Query MV for session totals

## Acceptance Criteria
- [ ] Session show page loads in < 100ms (currently ~300ms)
- [ ] Session PDF generates in < 300ms
- [ ] End-of-day reconciliation query returns in < 50ms
- [ ] System closing balance matches Ruby computation to centavo
- [ ] Variance amount matches `closing_declared - system_closing_balance`
- [ ] MV refresh completes in < 10 seconds
- [ ] No data discrepancy between MV and live entries

## Dependencies
- Unique index on `session_id` for `CONCURRENTLY` refresh
- pg_cron or Sidekiq with 1-min schedule
- Cash account must be correctly linked in entries

## Risks
- **Accuracy critical**: Cash discrepancies cause operational issues
- **Session lifecycle**: Open sessions have changing balances - refresh must capture latest
- **Void entries**: Voided entries must be excluded from MV (check `Entry#voided?`)
- **Timezone**: `DATE(e.entry_date)` must match session_date timezone