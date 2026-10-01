# PRD: Product Movement & Performance Materialized View

## Overview
Create materialized views for product-level analytics across all store fronts:
- Product movement (sales, purchases, transfers, returns)
- Product profitability (revenue, COGS, margin)
- Top/Bottom sellers
- Reorder recommendations
- Category performance

## Current Pain Points
- `Product.most_bought` loads all products and sorts in Ruby: `all.to_a.sort_by(&:line_items_count).reverse`
- `Product#balance()` iterates stocks across store fronts
- `Product#sales_balance()`, `purchases_balance()`, etc. each do separate queries
- Reports controller loads all products for XLSX export
- No pre-computed profitability per product

## Target Implementation

### 1. Product Daily Movement MV
```sql
CREATE MATERIALIZED VIEW mv_product_daily_movement AS
SELECT
  p.id AS product_id,
  p.name AS product_name,
  p.category_id,
  p.business_id,
  DATE(o.date) AS movement_date,
  -- Sales
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem' THEN li.quantity ELSE 0 END) AS units_sold,
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem' THEN li.total_cost ELSE 0 END) AS sales_revenue,
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem' THEN li.cost_of_goods_sold ELSE 0 END) AS sales_cogs,
  -- Sales Returns
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesReturnOrderLineItem' THEN li.quantity ELSE 0 END) AS units_returned,
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesReturnOrderLineItem' THEN li.total_cost ELSE 0 END) AS returns_value,
  -- Purchases
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::PurchaseOrderLineItem' THEN li.quantity ELSE 0 END) AS units_purchased,
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::PurchaseOrderLineItem' THEN li.total_cost ELSE 0 END) AS purchase_cost,
  -- Purchase Returns
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::PurchaseReturnOrderLineItem' THEN li.quantity ELSE 0 END) AS units_purchase_returned,
  -- Spoilage
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SpoilageOrderLineItem' THEN li.quantity ELSE 0 END) AS units_spoiled,
  -- Internal Use
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::InternalUseOrderLineItem' THEN li.quantity ELSE 0 END) AS units_internal_use,
  -- Transfers In/Out
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::StockTransferOrderLineItem' AND o.store_front_id = s.store_front_id THEN li.quantity ELSE 0 END) AS units_transferred_out,
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::StockTransferOrderLineItem' AND o.destination_store_front_id = s.store_front_id THEN li.quantity ELSE 0 END) AS units_transferred_in,
  -- Warranty
  SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::ForWarrantyOrderLineItem' THEN li.quantity ELSE 0 END) AS units_warranty
FROM products p
JOIN store_fronts_stocks s ON s.product_id = p.id
JOIN line_items li ON li.stock_id = s.id
JOIN orders o ON o.id = li.order_id
WHERE li.order_id IS NOT NULL
  AND o.date IS NOT NULL
GROUP BY p.id, p.name, p.category_id, p.business_id, DATE(o.date);

CREATE INDEX idx_mv_product_movement_product_date ON mv_product_daily_movement(product_id, movement_date);
CREATE INDEX idx_mv_product_movement_business_date ON mv_product_daily_movement(business_id, movement_date);
CREATE INDEX idx_mv_product_movement_category_date ON mv_product_daily_movement(category_id, movement_date);
```

### 2. Product Aggregate Summary MV (for dashboards)
```sql
CREATE MATERIALIZED VIEW mv_product_summary AS
SELECT
  p.id AS product_id,
  p.name AS product_name,
  p.category_id,
  p.business_id,
  p.retail_price,
  p.wholesale_price,
  p.low_stock_count,
  -- Lifetime aggregates
  COALESCE(SUM(m.units_sold), 0) AS total_units_sold,
  COALESCE(SUM(m.sales_revenue), 0) AS total_revenue,
  COALESCE(SUM(m.sales_cogs), 0) AS total_cogs,
  COALESCE(SUM(m.sales_revenue), 0) - COALESCE(SUM(m.sales_cogs), 0) AS total_gross_profit,
  CASE WHEN SUM(m.sales_revenue) > 0
    THEN (COALESCE(SUM(m.sales_revenue), 0) - COALESCE(SUM(m.sales_cogs), 0)) / SUM(m.sales_revenue) * 100
    ELSE 0 END AS gross_margin_pct,
  COALESCE(SUM(m.units_returned), 0) AS total_units_returned,
  COALESCE(SUM(m.units_purchased), 0) AS total_units_purchased,
  COALESCE(SUM(m.purchase_cost), 0) AS total_purchase_cost,
  COALESCE(SUM(m.units_spoiled), 0) AS total_units_spoiled,
  COALESCE(SUM(m.units_internal_use), 0) AS total_units_internal_use,
  COALESCE(SUM(m.units_warranty), 0) AS total_units_warranty,
  -- Current stock (from stock balance MV)
  COALESCE(ss.total_available, 0) AS current_stock,
  -- Velocity (units sold per day over last 30 days)
  COALESCE(
    SUM(CASE WHEN m.movement_date >= CURRENT_DATE - INTERVAL '30 days' THEN m.units_sold ELSE 0 END) / 30.0, 0
  ) AS daily_velocity_30d,
  -- Days of stock remaining
  CASE
    WHEN COALESCE(SUM(CASE WHEN m.movement_date >= CURRENT_DATE - INTERVAL '30 days' THEN m.units_sold ELSE 0 END) / 30.0, 0) > 0
    THEN COALESCE(ss.total_available, 0) / (SUM(CASE WHEN m.movement_date >= CURRENT_DATE - INTERVAL '30 days' THEN m.units_sold ELSE 0 END) / 30.0)
    ELSE NULL
  END AS days_of_stock_remaining,
  -- Last sale date
  MAX(CASE WHEN m.units_sold > 0 THEN m.movement_date END) AS last_sale_date,
  -- Last purchase date
  MAX(CASE WHEN m.units_purchased > 0 THEN m.movement_date END) AS last_purchase_date
FROM products p
LEFT JOIN mv_product_daily_movement m ON m.product_id = p.id
LEFT JOIN mv_product_stock_summary ss ON ss.product_id = p.id
GROUP BY p.id, p.name, p.category_id, p.business_id, p.retail_price, p.wholesale_price, p.low_stock_count, ss.total_available;

CREATE INDEX idx_mv_product_summary_business ON mv_product_summary(business_id);
CREATE INDEX idx_mv_product_summary_category ON mv_product_summary(category_id);
CREATE INDEX idx_mv_product_summary_velocity ON mv_product_summary(daily_velocity_30d DESC);
CREATE INDEX idx_mv_product_summary_margin ON mv_product_summary(gross_margin_pct DESC);
CREATE INDEX idx_mv_product_summary_stock ON mv_product_summary(days_of_stock_remaining);
```

### 3. Category Performance MV
```sql
CREATE MATERIALIZED VIEW mv_category_performance AS
SELECT
  c.id AS category_id,
  c.name AS category_name,
  c.business_id,
  COUNT(DISTINCT p.id) AS product_count,
  SUM(ps.total_units_sold) AS category_units_sold,
  SUM(ps.total_revenue) AS category_revenue,
  SUM(ps.total_cogs) AS category_cogs,
  SUM(ps.total_gross_profit) AS category_gross_profit,
  CASE WHEN SUM(ps.total_revenue) > 0
    THEN SUM(ps.total_gross_profit) / SUM(ps.total_revenue) * 100
    ELSE 0 END AS category_margin_pct,
  SUM(ps.current_stock) AS category_stock_value,
  AVG(ps.daily_velocity_30d) AS avg_daily_velocity
FROM categories c
JOIN products p ON p.category_id = c.id
JOIN mv_product_summary ps ON ps.product_id = p.id
GROUP BY c.id, c.name, c.business_id;

CREATE INDEX idx_mv_category_perf_business ON mv_category_performance(business_id);
```

## Query Patterns Supported

| Use Case | Current | With MV |
|----------|---------|---------|
| Top Sellers Report | `Product.most_bought` (loads all) | `SELECT * FROM mv_product_summary WHERE business_id = ? ORDER BY total_units_sold DESC LIMIT 20` |
| Product Profitability | Per-product queries | Single row from `mv_product_summary` |
| Reorder Report | Manual calc per product | `SELECT * FROM mv_product_summary WHERE days_of_stock_remaining < 14` |
| Category Performance | N/A | `SELECT * FROM mv_category_performance WHERE business_id = ?` |
| Slow Moving | N/A | `SELECT * FROM mv_product_summary WHERE daily_velocity_30d < 0.1 AND current_stock > 0` |
| XLSX Products Export | Load all products | `SELECT * FROM mv_product_summary WHERE business_id = ?` |

## Refresh Strategy
- **Frequency**: Every 30 minutes (analytics less time-critical)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY` (cascade: daily_movement → summary → category)
- **Trigger**: Scheduled job (pg_cron or Sidekiq)
- **Incremental**: Consider partitioning by date for large datasets

## Integration Points
1. **Product Model**: `most_bought`, `balance()`, `sales_balance()` → MV queries
2. **Reports::ProductsController**: Use `mv_product_summary` for XLSX
3. **Dashboard**: Top sellers, low stock, slow moving from MVs
4. **Reorder Alerts**: Background job queries `days_of_stock_remaining`

## Acceptance Criteria
- [ ] Top 20 sellers query returns in < 50ms (currently ~2s)
- [ ] Product profitability report loads in < 200ms
- [ ] Reorder report (10k products) generates in < 500ms
- [ ] Category performance loads in < 100ms
- [ ] Gross margin % matches manual calculation to 2 decimal places
- [ ] Days of stock remaining is accurate (velocity based on last 30 days)
- [ ] MV refresh cascade completes in < 60 seconds

## Dependencies
- `mv_product_stock_summary` from PRD 04 for current_stock
- `mv_product_daily_movement` as base for aggregates
- pg_cron with 30-min schedule
- Date partitioning consideration for `mv_product_daily_movement` if > 1M rows

## Risks
- **Data volume**: Daily movement grows unbounded - consider partitioning by month
- **Velocity calculation**: 30-day window must be recomputed on each refresh
- **Margin accuracy**: Ensure `sales_cogs` captures correct cost at time of sale
- **New products**: Products with no movement still need row in summary (LEFT JOIN handles this)