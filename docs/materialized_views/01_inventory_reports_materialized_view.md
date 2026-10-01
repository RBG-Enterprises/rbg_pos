# PRD: Inventory Reports Materialized View

## Overview
Convert the existing `inventory_reports` table (a manually rebuilt denormalized table) into a proper PostgreSQL **Materialized View** with automatic refresh capabilities.

## Current Implementation
- **Table**: `inventory_reports` (regular table, not a materialized view)
- **Rebuilder**: `InventoryReportRebuilder` service + `InventoryReportRebuilderJob` (scheduled job)
- **Source of Truth**: `LineItem` records across 8 line item types
- **Refresh Strategy**: Manual job run, typically scheduled via cron/sidekiq

## Target Implementation
- **Materialized View**: `mv_inventory_reports`
- **Refresh**: `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_inventory_reports`
- **Schedule**: Automated via pg_cron or application-level scheduler

## Data Definition
```sql
CREATE MATERIALIZED VIEW mv_inventory_reports AS
SELECT
  s.id AS stock_id,
  s.product_id,
  s.store_front_id,
  COALESCE(purchases.qty, 0) AS purchases,
  COALESCE(sales.qty, 0) AS sales,
  COALESCE(spoilage.qty, 0) AS spoilage,
  COALESCE(internal_use.qty, 0) AS internal_use,
  COALESCE(transfers.qty, 0) AS transfers,
  COALESCE(sales_returns.qty, 0) AS sales_returns,
  COALESCE(purchase_returns.qty, 0) AS purchase_returns,
  COALESCE(for_warranties.qty, 0) AS for_warranties,
  s.count_adjustment +
    COALESCE(purchases.qty, 0) +
    COALESCE(sales_returns.qty, 0) -
    COALESCE(purchase_returns.qty, 0) -
    COALESCE(transfers.qty, 0) -
    COALESCE(sales.qty, 0) -
    COALESCE(internal_use.qty, 0) -
    COALESCE(spoilage.qty, 0) -
    COALESCE(for_warranties.qty, 0) AS available
FROM store_fronts_stocks s
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::PurchaseOrderLineItem'
  GROUP BY stock_id
) purchases ON purchases.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::SalesOrderLineItem'
  GROUP BY stock_id
) sales ON sales.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::SpoilageOrderLineItem'
  GROUP BY stock_id
) spoilage ON spoilage.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::InternalUseOrderLineItem'
  GROUP BY stock_id
) internal_use ON internal_use.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::StockTransferOrderLineItem'
  GROUP BY stock_id
) transfers ON transfers.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::SalesReturnOrderLineItem'
  GROUP BY stock_id
) sales_returns ON sales_returns.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::PurchaseReturnOrderLineItem'
  GROUP BY stock_id
) purchase_returns ON purchase_returns.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::ForWarrantyOrderLineItem'
  GROUP BY stock_id
) for_warranties ON for_warranties.stock_id = s.id
WHERE s.is_processed = true;

CREATE UNIQUE INDEX idx_mv_inventory_reports_stock_id ON mv_inventory_reports(stock_id);
CREATE INDEX idx_mv_inventory_reports_product_id ON mv_inventory_reports(product_id);
CREATE INDEX idx_mv_inventory_reports_store_front_id ON mv_inventory_reports(store_front_id);
```

## Migration Strategy
1. Create materialized view with above SQL
2. Add `REFRESH MATERIALIZED VIEW CONCURRENTLY` to scheduled job
3. Update controller to query materialized view instead of table
4. Drop old `inventory_reports` table after verification
5. Update model `InventoryReport` to use `self.table_name = 'mv_inventory_reports'` and make it readonly

## Acceptance Criteria
- [ ] Materialized view returns identical data to current `inventory_reports` table
- [ ] `REFRESH MATERIALIZED VIEW CONCURRENTLY` completes in < 30 seconds
- [ ] CSV export from `InventoriesController#index` works identically
- [ ] XLSX export works identically (uses live computation, not MV)
- [ ] No application code breaks during migration
- [ ] Rollback plan documented

## Dependencies
- PostgreSQL 9.4+ (materialized views)
- pg_cron extension or Sidekiq scheduler for automated refresh
- Unique index on `stock_id` required for `CONCURRENTLY` refresh

## Risks
- Large datasets: `CONCURRENTLY` requires unique index; ensure `stock_id` is unique
- Stale data between refreshes: Document acceptable staleness window (e.g., 15 min)
- Migration downtime: Use dual-write period if needed