# PRD: Accounting Trial Balance & Financial Statements Materialized View

## Overview
Create a materialized view for pre-computed account balances (debits, credits, net) per date range to accelerate financial reports: Trial Balance, Income Statement, Balance Sheet, and General Ledger.

## Current Pain Points
- `Account.balance()`, `Account.debits_balance()`, `Account.credits_balance()` iterate all accounts and sum amounts in Ruby
- `Entry.total()` does `distinct.map { |a| a.credit_amounts.sum(:amount) }.sum` - N+1 queries
- Income Statement PDF generation queries all revenues/expenses and computes balances per account
- Cash Register Session PDF computes per-entry debit/credit sums in Ruby loops

## Target Implementation
**Materialized View**: `mv_account_balances`

Pre-computes per-account, per-day balances for fast date-range queries.

```sql
CREATE MATERIALIZED VIEW mv_account_balances AS
SELECT
  a.id AS account_id,
  a.name AS account_name,
  a.account_code,
  a.type AS account_type,
  a.business_id,
  DATE(e.entry_date) AS balance_date,
  SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END) AS total_debits,
  SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END) AS total_credits,
  SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END) -
  SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END) AS net_balance,
  COUNT(DISTINCT e.id) AS entry_count
FROM accounting_module_accounts a
JOIN accounting_module_amounts am ON am.account_id = a.id
JOIN accounting_module_entries e ON e.id = am.entry_id
WHERE e.entry_date IS NOT NULL
GROUP BY a.id, a.name, a.account_code, a.type, a.business_id, DATE(e.entry_date);

CREATE INDEX idx_mv_account_balances_account_date ON mv_account_balances(account_id, balance_date);
CREATE INDEX idx_mv_account_balances_business_date ON mv_account_balances(business_id, balance_date);
CREATE INDEX idx_mv_account_balances_type_date ON mv_account_balances(account_type, balance_date);
```

## Extended: Account Balance Summary View
For trial balance and financial statements, create a rollup view:

```sql
CREATE VIEW v_account_balance_summary AS
SELECT
  account_id,
  account_name,
  account_code,
  account_type,
  business_id,
  MIN(balance_date) AS first_entry_date,
  MAX(balance_date) AS last_entry_date,
  SUM(total_debits) AS lifetime_debits,
  SUM(total_credits) AS lifetime_credits,
  SUM(net_balance) AS lifetime_balance
FROM mv_account_balances
GROUP BY account_id, account_name, account_code, account_type, business_id;
```

## Query Patterns Supported
| Report | Current Query | With MV |
|--------|--------------|---------|
| Trial Balance | Iterate all accounts, call `balance()` | `SELECT * FROM v_account_balance_summary WHERE business_id = ?` |
| Income Statement | Query all Revenue/Expense accounts, call `balance(from_date, to_date)` | `SELECT * FROM mv_account_balances WHERE business_id = ? AND balance_date BETWEEN ? AND ? AND account_type IN ('Revenue','Expense')` |
| Balance Sheet | Query Asset/Liability/Equity accounts | Same as above with different type filter |
| General Ledger | Per-account, per-date drilldown | Direct query on `mv_account_balances` |

## Refresh Strategy
- **Frequency**: Every 5-15 minutes (configurable)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_account_balances`
- **Trigger**: After entry creation, or scheduled job
- **Incremental**: Consider `pg_cron` + `REFRESH CONCURRENTLY` (requires unique index on `(account_id, balance_date)`)

## Integration Points
1. **Account Model**: Add `materialized_balance(from_date, to_date)` method that queries MV
2. **Entry Model**: Replace `Entry.total()` with MV query
3. **PDF Reports**: Update `IncomeStatementPdf`, `TrialBalancePdf` to use MV
4. **Cash Register Session**: Use MV for beginning/ending balance computation

## Acceptance Criteria
- [ ] Trial Balance report loads in < 500ms (currently ~3-5s)
- [ ] Income Statement PDF generates in < 1s (currently ~2-3s)
- [ ] Balance Sheet loads in < 500ms
- [ ] General Ledger drilldown works with date filters
- [ ] MV refresh completes in < 60 seconds
- [ ] Data matches current Ruby-computed balances to the cent
- [ ] No regression in existing specs

## Dependencies
- Unique index on `(account_id, balance_date)` for `CONCURRENTLY` refresh
- pg_cron or Sidekiq scheduler
- Migration script to backfill historical data

## Risks
- Data volume: `accounting_module_amounts` × entries × date granularity
- Staleness: Financial reports may show slightly stale data between refreshes
- Contra accounts: Ensure `contra` flag logic is correctly applied in MV