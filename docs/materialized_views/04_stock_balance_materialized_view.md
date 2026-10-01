# PRD: Stock Balance & Movement Materialized View

## Overview
Create materialized views for real-time stock balance queries and cross-store availability lookups to eliminate N+1 queries in:
- Stock detail pages (movement counts, supplier info)
- Same-barcode cross-store summary
- Inventory overview dashboards
- Low stock / out of stock alerts

## Current Pain Points
- `StockOverview` concern runs 5+ queries per stock detail page
- `Product#balance()` iterates stocks and calls `Stock#balance` which sums 8 line item types
- `Stock#balance` does 8 separate association loads + sums
- `same_barcode_summary` does 2 grouped queries per request
- `inventories_controller.rb` XLSX export does 7 separate grouped queries per stock batch

## Target Implementation

### 1. Stock Balance Snapshot MV (per stock, current state)
```sql
CREATE MATERIALIZED VIEW mv_stock_balance AS
SELECT
  s.id AS stock_id,
  s.product_id,
  s.store_front_id,
  s.barcode,
  s.unit_of_measurement_id,
  s.available_quantity,
  s.count_adjustment,
  s.is_processed,
  s.updated_at AS last_movement_at,
  -- Pre-computed balances from line items
  COALESCE(purchases.qty, 0) AS purchase_qty,
  COALESCE(sales.qty, 0) AS sales_qty,
  COALESCE(spoilage.qty, 0) AS spoilage_qty,
  COALESCE(internal_use.qty, 0) AS internal_use_qty,
  COALESCE(transfers.qty, 0) AS transfer_qty,
  COALESCE(sales_returns.qty, 0) AS sales_return_qty,
  COALESCE(purchase_returns.qty, 0) AS purchase_return_qty,
  COALESCE(for_warranties.qty, 0) AS for_warranty_qty,
  -- Computed balance (mirrors Stock#balance)
  s.count_adjustment +
    COALESCE(purchases.qty, 0) +
    COALESCE(sales_returns.qty, 0) -
    COALESCE(purchase_returns.qty, 0) -
    COALESCE(transfers.qty, 0) -
    COALESCE(sales.qty, 0) -
    COALESCE(internal_use.qty, 0) -
    COALESCE(spoilage.qty, 0) -
    COALESCE(for_warranties.qty, 0) AS computed_balance,
  -- Movement counts
  COALESCE(purchases.cnt, 0) AS purchase_count,
  COALESCE(sales.cnt, 0) AS sales_count,
  COALESCE(spoilage.cnt, 0) AS spoilage_count,
  COALESCE(internal_use.cnt, 0) AS internal_use_count,
  COALESCE(transfers.cnt, 0) AS transfer_count,
  COALESCE(sales_returns.cnt, 0) AS sales_return_count,
  COALESCE(purchase_returns.cnt, 0) AS purchase_return_count,
  COALESCE(for_warranties.cnt, 0) AS for_warranty_count
FROM store_fronts_stocks s
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::PurchaseOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) purchases ON purchases.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::SalesOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) sales ON sales.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::SpoilageOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) spoilage ON spoilage.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::InternalUseOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) internal_use ON internal_use.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::StockTransferOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) transfers ON transfers.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::SalesReturnOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) sales_returns ON sales_returns.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::PurchaseReturnOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) purchase_returns ON purchase_returns.stock_id = s.id
LEFT JOIN (
  SELECT stock_id, SUM(quantity) AS qty, COUNT(*) AS cnt
  FROM line_items
  WHERE type = 'StoreFrontModule::LineItems::ForWarrantyOrderLineItem' AND order_id IS NOT NULL
  GROUP BY stock_id
) for_warranties ON for_warranties.stock_id = s.id
WHERE s.is_processed = true;

CREATE UNIQUE INDEX idx_mv_stock_balance_stock_id ON mv_stock_balance(stock_id);
CREATE INDEX idx_mv_stock_balance_product_store ON mv_stock_balance(product_id, store_front_id);
CREATE INDEX idx_mv_stock_balance_barcode ON mv_stock_balance(barcode);
CREATE INDEX idx_mv_stock_balance_store_processed ON mv_stock_balance(store_front_id, is_processed);
```

### 2. Cross-Store Barcode Availability MV
```sql
CREATE MATERIALIZED VIEW mv_barcode_cross_store_availability AS
SELECT
  s.barcode,
  s.product_id,
  p.name AS product_name,
  s.store_front_id,
  sf.name AS store_front_name,
  mb.computed_balance AS available_quantity,
  s.updated_at AS last_updated_at
FROM mv_stock_balance mb
JOIN store_fronts_stocks s ON s.id = mb.stock_id
JOIN store_fronts sf ON sf.id = s.store_front_id
JOIN products p ON p.id = s.product_id
WHERE s.barcode IS NOT NULL
  AND s.barcode != ''
  AND mb.computed_balance > 0;

CREATE INDEX idx_mv_barcode_store ON mv_barcode_cross_store_availability(barcode, store_front_id);
```

### 3. Product-Level Aggregate MV (for low stock alerts)
```sql
CREATE MATERIALIZED VIEW mv_product_stock_summary AS
SELECT
  p.id AS product_id,
  p.name AS product_name,
  p.category_id,
  p.low_stock_count,
  p.business_id,
  SUM(mb.computed_balance) AS total_available,
  COUNT(DISTINCT mb.store_front_id) AS store_fronts_count,
  MIN(mb.computed_balance) AS min_per_store,
  MAX(mb.computed_balance) AS max_per_store,
  BOOL_OR(mb.computed_balance <= p.low_stock_count) AS is_low_stock_any_store,
  BOOL_OR(mb.computed_balance <= 0) AS is_out_of_stock_any_store
FROM mv_stock_balance mb
JOIN products p ON p.id = mb.product_id
GROUP BY p.id, p.name, p.category_id, p.low_stock_count, p.business_id;

CREATE INDEX idx_mv_product_stock_business ON mv_product_stock_summary(business_id);
CREATE INDEX idx_mv_product_stock_low ON mv_product_stock_summary(is_low_stock_any_store, is_out_of_stock_any_store);
```

## Query Patterns Supported

| Use Case | Current | With MV |
|----------|---------|---------|
| Stock detail page | 5+ queries + Ruby sums | Single row from `mv_stock_balance` |
| Same-barcode summary | 2 grouped queries | `SELECT * FROM mv_barcode_cross_store_availability WHERE barcode = ?` |
| Low stock dashboard | Iterate all products, call `balance()` | `SELECT * FROM mv_product_stock_summary WHERE is_low_stock_any_store` |
| XLSX inventory export | 7 grouped queries per batch | Single query on `mv_stock_balance` |
| Product balance | `Product#balance()` loops stocks | `SELECT total_available FROM mv_product_stock_summary WHERE product_id = ?` |

## Refresh Strategy
- **Frequency**: Every 2-5 minutes (high frequency for POS accuracy)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_stock_balance` (cascades to dependent MVs)
- **Trigger**: After line item creation (order completion), stock adjustment
- **Incremental**: Consider trigger-based refresh for critical stocks

## Integration Points
1. **Stock Model**: Add `materialized_balance` method reading from MV
2. **StockOverview Concern**: Replace all queries with MV lookups
3. **InventoriesController**: Use `mv_stock_balance` for XLSX/CSV
4. **Product Model**: `balance()`, `low_on_stock?`, `out_of_stock?` use `mv_product_stock_summary`
5. **Low Stock Alerts**: Background job queries `mv_product_stock_summary`

## Acceptance Criteria
- [ ] Stock detail page loads in < 100ms (currently ~500ms)
- [ ] Same-barcode summary returns in < 50ms
- [ ] Low stock dashboard loads in < 200ms for 10k products
- [ ] XLSX inventory export generates in < 1s (currently ~5-10s)
- [ ] Computed balance matches `Stock#balance` to 3 decimal places
- [ ] MV refresh completes in < 20 seconds
- [ ] No stale data > 5 minutes during business hours

## Dependencies
- `mv_inventory_reports` MV (PRD 01) can share base aggregates
- Unique index on `stock_id` for `CONCURRENTLY` refresh
- pg_cron or Sidekiq with 2-min schedule

## Risks
- **Staleness critical**: POS operations need near-real-time stock
- **Write contention**: High line_item insert rate during peak hours
- **Cascade refresh**: Dependent MVs must refresh in order
- **Decimal precision**: Ensure `quantity` sums preserve precision