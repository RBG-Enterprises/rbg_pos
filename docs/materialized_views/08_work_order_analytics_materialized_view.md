# PRD: Work Order Analytics Materialized View

## Overview
Create materialized views for work order reporting and technician performance:
- Work order status tracking
- Technician productivity
- Service revenue analysis
- Parts usage
- Turnaround time metrics

## Current Pain Points
- `ReleasedWorkOrdersController` queries work orders per employee
- `RepairsController` filters by employee and date range
- `WorkOrder#balance_total` does per-work-order account balance queries
- Technician dashboard (`PerEmployeeDashboardsController`) loads work orders and computes metrics in Ruby
- No pre-computed turnaround times or completion rates

## Target Implementation

### 1. Work Order Daily Summary MV
```sql
CREATE MATERIALIZED VIEW mv_work_order_daily AS
SELECT
  wo.id AS work_order_id,
  wo.service_number,
  wo.store_front_id,
  wo.technician_id,
  wo.customer_id,
  wo.work_order_category_id,
  wo.status,
  wo.under_warranty,
  wo.date_received,
  wo.release_date,
  wo.done_at,
  wo.time_received,
  -- Time metrics (in hours)
  CASE
    WHEN wo.done_at IS NOT NULL AND wo.date_received IS NOT NULL
    THEN EXTRACT(EPOCH FROM (wo.done_at - wo.date_received)) / 3600.0
    ELSE NULL END AS turnaround_hours,
  CASE
    WHEN wo.done_at IS NOT NULL AND wo.time_received IS NOT NULL
    THEN EXTRACT(EPOCH FROM (wo.done_at - wo.time_received)) / 3600.0
    ELSE NULL END AS active_hours,
  -- Revenue
  wo.total_cost AS service_revenue,
  -- Parts cost (from line items)
  COALESCE(
    SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem' THEN li.cost_of_goods_sold ELSE 0 END), 0
  ) AS parts_cogs,
  -- Labor cost (if tracked separately)
  wo.total_cost - COALESCE(
    SUM(CASE WHEN li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem' THEN li.cost_of_goods_sold ELSE 0 END), 0
  ) AS labor_revenue,
  -- Service charges
  COALESCE(
    SUM(wosc.amount), 0
  ) AS service_charges_total
FROM work_orders wo
LEFT JOIN line_items li ON li.order_id = wo.id AND li.type = 'StoreFrontModule::LineItems::SalesOrderLineItem'
LEFT JOIN work_order_service_charges wosc ON wosc.work_order_id = wo.id
GROUP BY wo.id, wo.service_number, wo.store_front_id, wo.technician_id, wo.customer_id,
         wo.work_order_category_id, wo.status, wo.under_warranty, wo.date_received,
         wo.release_date, wo.done_at, wo.time_received, wo.total_cost;

CREATE INDEX idx_mv_wo_daily_tech_date ON mv_work_order_daily(technician_id, date_received);
CREATE INDEX idx_mv_wo_daily_store_date ON mv_work_order_daily(store_front_id, date_received);
CREATE INDEX idx_mv_wo_daily_status ON mv_work_order_daily(status);
CREATE INDEX idx_mv_wo_daily_category ON mv_work_order_daily(work_order_category_id);
```

### 2. Technician Performance MV
```sql
CREATE MATERIALIZED VIEW mv_technician_performance AS
SELECT
  u.id AS technician_id,
  u.first_name || ' ' || u.last_name AS technician_name,
  u.store_front_id,
  DATE_TRUNC('month', wo.date_received)::date AS performance_month,
  COUNT(*) AS total_work_orders,
  COUNT(*) FILTER (WHERE wo.status = 2) AS completed_count, -- assuming 2 = completed
  COUNT(*) FILTER (WHERE wo.status = 0) AS pending_count,
  COUNT(*) FILTER (WHERE wo.status = 1) AS in_progress_count,
  COUNT(*) FILTER (WHERE wo.under_warranty) AS warranty_count,
  AVG(
    CASE WHEN wo.done_at IS NOT NULL AND wo.date_received IS NOT NULL
    THEN EXTRACT(EPOCH FROM (wo.done_at - wo.date_received)) / 3600.0 END
  ) AS avg_turnaround_hours,
  PERCENTILE_CONT(0.5) WITHIN GROUP (
    ORDER BY CASE WHEN wo.done_at IS NOT NULL AND wo.date_received IS NOT NULL
    THEN EXTRACT(EPOCH FROM (wo.done_at - wo.date_received)) / 3600.0 END
  ) AS median_turnaround_hours,
  SUM(wo.total_cost) AS total_revenue,
  SUM(wo.total_cost) FILTER (WHERE wo.under_warranty) AS warranty_revenue,
  SUM(wo.total_cost) FILTER (WHERE NOT wo.under_warranty) AS paid_revenue,
  AVG(wo.total_cost) AS avg_revenue_per_order,
  COUNT(DISTINCT wo.customer_id) AS unique_customers
FROM users u
JOIN work_orders wo ON wo.technician_id = u.id
WHERE u.designation = 'technician' -- or role check
GROUP BY u.id, u.first_name, u.last_name, u.store_front_id, DATE_TRUNC('month', wo.date_received);

CREATE INDEX idx_mv_tech_perf_tech_month ON mv_technician_performance(technician_id, performance_month);
CREATE INDEX idx_mv_tech_perf_store_month ON mv_technician_performance(store_front_id, performance_month);
```

### 3. Work Order Category Performance MV
```sql
CREATE MATERIALIZED VIEW mv_work_order_category_performance AS
SELECT
  woc.id AS category_id,
  woc.title AS category_name,
  wo.store_front_id,
  DATE_TRUNC('month', wo.date_received)::date AS month,
  COUNT(*) AS total_orders,
  AVG(
    CASE WHEN wo.done_at IS NOT NULL AND wo.date_received IS NOT NULL
    THEN EXTRACT(EPOCH FROM (wo.done_at - wo.date_received)) / 3600.0 END
  ) AS avg_turnaround_hours,
  SUM(wo.total_cost) AS total_revenue,
  COUNT(*) FILTER (WHERE wo.under_warranty) AS warranty_orders,
  COUNT(*) FILTER (WHERE wo.status = 2) AS completed_orders
FROM work_order_categories woc
JOIN work_orders wo ON wo.work_order_category_id = woc.id
GROUP BY woc.id, woc.title, wo.store_front_id, DATE_TRUNC('month', wo.date_received);

CREATE INDEX idx_mv_wo_cat_store_month ON mv_work_order_category_performance(store_front_id, month);
```

## Query Patterns Supported

| Use Case | Current | With MV |
|----------|---------|---------|
| Technician Dashboard | Load WOs, compute in Ruby | `SELECT * FROM mv_technician_performance WHERE technician_id = ? AND performance_month = ?` |
| Released WOs Report | Query WOs per employee | `SELECT * FROM mv_work_order_daily WHERE technician_id = ? AND date_received BETWEEN ? AND ?` |
| Category Analysis | N/A | `SELECT * FROM mv_work_order_category_performance WHERE store_front_id = ?` |
| Turnaround Report | Manual calc | MV has pre-computed hours |
| Warranty vs Paid Split | Filter in Ruby | `warranty_revenue` / `paid_revenue` columns |

## Refresh Strategy
- **Frequency**: Every 15 minutes (work orders less frequent than POS)
- **Method**: `REFRESH MATERIALIZED VIEW CONCURRENTLY`
- **Trigger**: After work order status change, completion, or new WO
- **Monthly rollups**: Technician/category performance can refresh hourly

## Integration Points
1. **WorkOrder Model**: Add `turnaround_hours` method reading from MV
2. **Technician Dashboard**: Query `mv_technician_performance`
3. **ReleasedWorkOrdersController**: Use `mv_work_order_daily`
4. **RepairsController**: Use `mv_work_order_daily` with filters
5. **Management Reports**: Category performance, technician leaderboards

## Acceptance Criteria
- [ ] Technician dashboard loads in < 200ms (currently ~1-2s)
- [ ] Released WOs report generates in < 300ms
- [ ] Turnaround time matches `done_at - date_received` to the minute
- [ ] Revenue totals match `WorkOrder#total_cost` sum
- [ ] Warranty/paid split is accurate
- [ ] MV refresh completes in < 20 seconds

## Dependencies
- `work_orders.done_at` and `date_received` must be populated
- `technician_id` must be set on work orders
- `work_order_service_charges` for service charge totals
- pg_cron with 15-min schedule

## Risks
- **Status codes**: Ensure status integer values match application constants
- **Timezone**: `date_received` and `done_at` timezone consistency
- **Null handling**: In-progress WOs have null `done_at` - exclude from turnaround avg
- **Monthly buckets**: `DATE_TRUNC('month')` uses database timezone