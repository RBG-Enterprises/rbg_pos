# PRD: Customer & Supplier AR/AP Balances Materialized View

## Overview
Create materialized views for pre-computed Accounts Receivable (Customer) and Accounts Payable (Supplier) balances with aging buckets to accelerate:
- AR/AP Reports (PDF, CSV)
- Customer/Supplier balance inquiries
- Credit limit checking
- Collection/ Payment dashboards

## Current Pain Points
- `Customer.with_credits` scope + `Customer#balance_total` does per-customer account balance queries
- `Supplier#balance_total` queries payable account per supplier
- `AccountsReceivablesController` loads all customers and computes balances in Ruby
- `AccountsReceivablesPdf` iterates customers and calls `balance_total`
- No aging buckets - all balances are current only

## Target Implementation

### 1. Customer AR Balance MV (with aging)
```sql
CREATE MATERIALIZED VIEW mv_customer_ar_balance AS
WITH customer_entries AS (
  SELECT
    c.id AS customer_id,
    c.business_id,
    c.name AS customer_name,
    c.account_number,
    c.receivable_account_id,
    c.receivable_balance AS legacy_balance,
    e.id AS entry_id,
    e.entry_date,
    e.commercial_document_type,
    e.commercial_document_id,
    am.type AS amount_type,
    am.amount,
    am.account_id
  FROM customers c
  JOIN accounting_module_accounts a ON a.id = c.receivable_account_id
  JOIN accounting_module_amounts am ON am.account_id = a.id
  JOIN accounting_module_entries e ON e.id = am.entry_id
  WHERE e.entry_date IS NOT NULL
),
aggregated AS (
  SELECT
    customer_id,
    business_id,
    customer_name,
    account_number,
    receivable_account_id,
    -- Current balance (all time)
    SUM(CASE WHEN amount_type = 'AccountingModule::DebitAmount' THEN amount ELSE 0 END) -
    SUM(CASE WHEN amount_type = 'AccountingModule::CreditAmount' THEN amount ELSE 0 END) AS current_balance,
    -- Aging buckets (relative to today)
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) AS balance_0_30,
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '60 days'
      AND entry_date < CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '60 days'
      AND entry_date < CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) AS balance_31_60,
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '90 days'
      AND entry_date < CURRENT_DATE - INTERVAL '60 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '90 days'
      AND entry_date < CURRENT_DATE - INTERVAL '60 days' THEN amount ELSE 0 END) AS balance_61_90,
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date < CURRENT_DATE - INTERVAL '90 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date < CURRENT_DATE - INTERVAL '90 days' THEN amount ELSE 0 END) AS balance_over_90,
    MAX(entry_date) AS last_activity_date,
    COUNT(DISTINCT entry_id) AS transaction_count
  FROM customer_entries
  GROUP BY customer_id, business_id, customer_name, account_number, receivable_account_id
)
SELECT * FROM aggregated
WHERE current_balance != 0; -- Only customers with open balance

CREATE INDEX idx_mv_customer_ar_business ON mv_customer_ar_balance(business_id);
CREATE INDEX idx_mv_customer_ar_balance ON mv_customer_ar_balance(current_balance);
CREATE INDEX idx_mv_customer_ar_aging ON mv_customer_ar_balance(balance_over_90);
```

### 2. Supplier AP Balance MV (with aging)
```sql
CREATE MATERIALIZED VIEW mv_supplier_ap_balance AS
WITH supplier_entries AS (
  SELECT
    s.id AS supplier_id,
    s.business_id,
    s.name AS supplier_name,
    s.business_name,
    s.payable_account_id,
    e.id AS entry_id,
    e.entry_date,
    am.type AS amount_type,
    am.amount
  FROM suppliers s
  JOIN accounting_module_accounts a ON a.id = s.payable_account_id
  JOIN accounting_module_amounts am ON am.account_id = a.id
  JOIN accounting_module_entries e ON e.id = am.entry_id
  WHERE e.entry_date IS NOT NULL
),
aggregated AS (
  SELECT
    supplier_id,
    business_id,
    supplier_name,
    business_name,
    payable_account_id,
    -- Current balance (credit - debit for liability)
    SUM(CASE WHEN amount_type = 'AccountingModule::CreditAmount' THEN amount ELSE 0 END) -
    SUM(CASE WHEN amount_type = 'AccountingModule::DebitAmount' THEN amount ELSE 0 END) AS current_balance,
    -- Aging buckets
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) AS balance_0_30,
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '60 days'
      AND entry_date < CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '60 days'
      AND entry_date < CURRENT_DATE - INTERVAL '30 days' THEN amount ELSE 0 END) AS balance_31_60,
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '90 days'
      AND entry_date < CURRENT_DATE - INTERVAL '60 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date >= CURRENT_DATE - INTERVAL '90 days'
      AND entry_date < CURRENT_DATE - INTERVAL '60 days' THEN amount ELSE 0 END) AS balance_61_90,
    SUM(CASE
      WHEN amount_type = 'AccountingModule::CreditAmount'
      AND entry_date < CURRENT_DATE - INTERVAL '90 days' THEN amount ELSE 0 END) -
    SUM(CASE
      WHEN amount_type = 'AccountingModule::DebitAmount'
      AND entry_date < CURRENT_DATE - INTERVAL '90 days' THEN amount ELSE 0 END) AS balance_over_90,
    MAX(entry_date) AS last_activity_date,
    COUNT(DISTINCT entry_id) AS transaction_count
  FROM supplier_entries
  GROUP BY supplier_id, business_id, supplier_name, business_name, payable_account_id
)
SELECT * FROM aggregated
WHERE current_balance != 0;

CREATE INDEX idx_mv_supplier_ap_business ON mv_supplier_ap_balance(business_id);
CREATE INDEX idx_mv_supplier_ap_balance ON mv_supplier_ap_balance(current_balance);
CREATE INDEX idx_mv_supplier_ap_aging ON mv_supplier_ap_balance(balance_over_90);
```

### 3. Customer/Supplier Credit Limit MV (for POS validation)
```sql
CREATE MATERIALIZED VIEW mv_customer_credit_status AS
SELECT
  c.id AS customer_id,
  c.business_id,
  c.name AS customer_name,
  c.account_number,
  c.receivable_account_id,
  COALESCE(ar.current_balance, 0) AS current_ar_balance,
  COALESCE(ar.balance_over_90, 0) AS over_90_balance,
  -- Credit limit from customer config or business config
  c.credit_limit, -- Add column to customers table if needed
  CASE
    WHEN c.credit_limit IS NULL THEN 'unlimited'
    WHEN COALESCE(ar.current_balance, 0) >= c.credit_limit THEN 'exceeded'
    WHEN COALESCE(ar.current_balance, 0) >= c.credit_limit * 0.8 THEN 'warning'
    ELSE 'ok'
  END AS credit_status
FROM customers c
LEFT JOIN mv_customer_ar_balance ar ON ar.customer_id = c.id;

CREATE INDEX idx_mv_credit_status_business ON mv_customer_credit_status(business_id);
CREATE INDEX idx_mv_credit_status_check ON mv_customer_credit_status(credit_status);
```

## Query Patterns Supported

| Use Case | Current | With MV |
|----------|---------|---------|
| AR Report (all customers) | Load all, compute each | `SELECT * FROM mv_customer_ar_balance WHERE business_id = ?` |
| AR Aging Report | Manual aging calc | MV has pre-computed buckets |
| Customer balance check | `customer.balance_total` | `SELECT current_balance FROM mv_customer_ar_balance WHERE customer_id = ?` |
| Credit limit check at POS | Query customer, compute | `SELECT credit_status FROM mv_customer_credit_status WHERE customer_id = ?` |
| Supplier AP Report | Load all, compute each | `SELECT * FROM mv_supplier_ap_balance WHERE business_id = ?` |

## Refresh Strategy
- **Frequency**: Every 15 minutes (AR/AP less time-critical than cash/stock)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY`
- **Trigger**: After entry creation affecting AR/AP accounts
- **Note**: Aging buckets use `CURRENT_DATE` - MV must refresh daily for accurate aging

## Integration Points
1. **Customer Model**: `balance_total` → MV query
2. **Supplier Model**: `balance_total` → MV query
3. **AccountsReceivablesController**: Use MV directly
4. **AccountsReceivablesPdf**: Query MV with aging buckets
5. **POS Credit Check**: Query `mv_customer_credit_status`

## Acceptance Criteria
- [ ] AR Report PDF generates in < 500ms (currently ~3-5s)
- [ ] AP Report PDF generates in < 500ms
- [ ] Aging buckets match manual calculation to centavo
- [ ] Customer balance check at POS returns in < 20ms
- [ ] Credit status (ok/warning/exceeded) is accurate
- [ ] MV refresh completes in < 30 seconds
- [ ] Zero-balance customers correctly excluded from MV

## Dependencies
- `receivable_account_id` and `payable_account_id` must be set on customers/suppliers
- Unique index on `customer_id`/`supplier_id` for `CONCURRENTLY` refresh
- pg_cron with 15-min schedule + daily refresh for aging accuracy

## Risks
- **Aging accuracy**: MV aging uses `CURRENT_DATE` at refresh time, not query time
- **Credit limits**: Need `credit_limit` column on customers table
- **Contra accounts**: Ensure contra logic matches `Account#balance()`
- **Multi-business**: Filter by `business_id` in all queries