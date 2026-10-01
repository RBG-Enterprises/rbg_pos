# PRD: Sales Reports Materialized View

## Overview
Create materialized views for pre-aggregated sales data to accelerate:
- Daily/Monthly Sales Reports (CSV, PDF, XLSX)
- Cash Receipts Reports
- Employee Sales Performance Dashboards
- Store Front Sales Summaries

## Current Pain Points
- `SalesController#index` and `SalesPdf` compute totals by iterating orders in Ruby
- `cash_on_hand_account.debits_balance()` and `credits_balance()` query amounts per date range
- `CashReceiptsPdf` does per-entry amount lookups in Ruby loops
- Employee sales dashboard queries orders and line items per request

## Target Implementation

### 1. Daily Sales Summary MV
```sql
CREATE MATERIALIZED VIEW mv_daily_sales_summary AS
SELECT
  o.store_front_id,
  o.employee_id,
  o.cash_register_session_id,
  DATE(o.date) AS sale_date,
  COUNT(DISTINCT o.id) AS order_count,
  SUM(oi.total_cost) AS gross_sales,
  SUM(oi.total_cost) - SUM(COALESCE(cp.discount_amount, 0)) AS net_sales,
  SUM(COALESCE(cp.discount_amount, 0)) AS total_discounts,
  SUM(oi.cost_of_goods_sold) AS total_cogs,
  SUM(oi.total_cost) - SUM(COALESCE(cp.discount_amount, 0)) - SUM(oi.cost_of_goods_sold) AS gross_profit,
  SUM(COALESCE(cp.cash_tendered, 0)) AS cash_collected,
  SUM(COALESCE(cp.cash_change, 0)) AS cash_change_given
FROM orders o
JOIN line_items oi ON oi.order_id = o.id
LEFT JOIN store_front_module_cash_payments cp ON cp.cash_paymentable_id = o.id AND cp.cash_paymentable_type = 'Order'
WHERE o.type = 'StoreFrontModule::Orders::SalesOrder'
  AND o.id IS NOT NULL
GROUP BY o.store_front_id, o.employee_id, o.cash_register_session_id, DATE(o.date);

CREATE INDEX idx_mv_daily_sales_store_date ON mv_daily_sales_summary(store_front_id, sale_date);
CREATE INDEX idx_mv_daily_sales_employee_date ON mv_daily_sales_summary(employee_id, sale_date);
CREATE INDEX idx_mv_daily_sales_session_date ON mv_daily_sales_summary(cash_register_session_id, sale_date);
```

### 2. Sales Line Item Detail MV (for drilldown)
```sql
CREATE MATERIALIZED VIEW mv_sales_line_items AS
SELECT
  o.id AS order_id,
  o.reference_number,
  o.date AS order_date,
  o.store_front_id,
  o.employee_id,
  o.customer_id,
  c.name AS customer_name,
  li.id AS line_item_id,
  li.product_id,
  p.name AS product_name,
  li.bar_code,
  li.quantity,
  li.unit_cost,
  li.total_cost,
  li.cost_of_goods_sold
FROM orders o
JOIN line_items li ON li.order_id = o.id
JOIN products p ON p.id = li.product_id
LEFT JOIN customers c ON c.id = o.commercial_document_id AND o.commercial_document_type = 'Customer'
WHERE o.type = 'StoreFrontModule::Orders::SalesOrder'
  AND li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem';

CREATE INDEX idx_mv_sales_li_order ON mv_sales_line_items(order_id);
CREATE INDEX idx_mv_sales_li_product_date ON mv_sales_line_items(product_id, order_date);
CREATE INDEX idx_mv_sales_li_store_date ON mv_sales_line_items(store_front_id, order_date);
```

### 3. Cash Account Daily Balance MV
```sql
CREATE MATERIALIZED VIEW mv_cash_account_daily_balance AS
SELECT
  ca.id AS cash_account_id,
  ca.user_id AS employee_id,
  DATE(e.entry_date) AS balance_date,
  SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END) AS daily_debits,
  SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END) AS daily_credits,
  SUM(CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END) -
  SUM(CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END) AS net_change,
  -- Running balance requires window function
  SUM(
    CASE WHEN am.type = 'AccountingModule::DebitAmount' THEN am.amount ELSE 0 END
  ) OVER (PARTITION BY ca.id ORDER BY DATE(e.entry_date)
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) -
  SUM(
    CASE WHEN am.type = 'AccountingModule::CreditAmount' THEN am.amount ELSE 0 END
  ) OVER (PARTITION BY ca.id ORDER BY DATE(e.entry_date)
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM accounting_module_accounts ca
JOIN accounting_module_amounts am ON am.account_id = ca.id
JOIN accounting_module_entries e ON e.id = am.entry_id
WHERE ca.id IN (SELECT cash_on_hand_account_id FROM users WHERE cash_on_hand_account_id IS NOT NULL)
  AND e.entry_date IS NOT NULL
GROUP BY ca.id, ca.user_id, DATE(e.entry_date);

CREATE INDEX idx_mv_cash_bal_account_date ON mv_cash_account_daily_balance(cash_account_id, balance_date);
```

## Query Patterns Supported

| Report | Current | With MV |
|--------|---------|---------|
| Sales Report (date range) | Iterate orders, sum in Ruby | `SELECT * FROM mv_daily_sales_summary WHERE sale_date BETWEEN ? AND ? AND store_front_id = ?` |
| Employee Sales | Filter by employee, sum | `SELECT * FROM mv_daily_sales_summary WHERE employee_id = ? AND sale_date BETWEEN ? AND ?` |
| Cash Receipts | Per-entry debit lookup | `SELECT * FROM mv_cash_account_daily_balance WHERE cash_account_id = ? AND balance_date BETWEEN ? AND ?` |
| Sales Drilldown | N+1 line item queries | `SELECT * FROM mv_sales_line_items WHERE order_id IN (...)` |

## Refresh Strategy
- **Frequency**: Every 5 minutes (high priority for cash balancing)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY`
- **Trigger**: After sales order completion (voucher confirmation)
- **Incremental**: Consider using `pg_cron` with 5-min schedule

## Integration Points
1. **SalesController**: Replace Ruby aggregation with MV query
2. **SalesPdf**: Use MV for summary totals, line item MV for detail
3. **CashReceiptsPdf**: Query `mv_cash_account_daily_balance`
4. **Employee Dashboard**: Query `mv_daily_sales_summary` by employee

## Acceptance Criteria
- [ ] Sales Report CSV generates in < 200ms (currently ~2-3s)
- [ ] Sales PDF renders in < 500ms
- [ ] Cash Receipts PDF renders in < 300ms
- [ ] Employee sales dashboard loads in < 200ms
- [ ] Data matches current reports to the centavo
- [ ] MV refresh completes in < 30 seconds
- [ ] Running balance in `mv_cash_account_daily_balance` is correct

## Dependencies
- PostgreSQL window functions for running balance
- Unique index on `(store_front_id, sale_date)` for `CONCURRENTLY` refresh
- pg_cron or Sidekiq scheduler

## Risks
- Cash account balance must be 100% accurate - validate running balance logic
- High write volume on orders table - ensure MV refresh doesn't lock
- Date boundaries: ensure `DATE(o.date)` matches application timezone