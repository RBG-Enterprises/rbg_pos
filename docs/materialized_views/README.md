# Materialized Views Implementation - Master Index

## Overview
This directory contains 8 PRDs for converting key reporting and analytics queries in the RBG POS system from on-demand Ruby computations to pre-computed PostgreSQL Materialized Views.

## PRD Summary

| # | PRD | Target Tables | Refresh Freq | Priority |
|---|-----|---------------|--------------|----------|
| 01 | [Inventory Reports](./01_inventory_reports_materialized_view.md) | `inventory_reports` → `mv_inventory_reports` | 5-15 min | **Critical** (already implemented as table) |
| 02 | [Accounting Financials](./02_accounting_financials_materialized_view.md) | `mv_account_balances`, `v_account_balance_summary` | 5-15 min | **High** (Trial Balance, Income Stmt) |
| 03 | [Sales Reports](./03_sales_reports_materialized_view.md) | `mv_daily_sales_summary`, `mv_sales_line_items`, `mv_cash_account_daily_balance` | 5 min | **High** (POS reports, cash balancing) |
| 04 | [Stock Balance](./04_stock_balance_materialized_view.md) | `mv_stock_balance`, `mv_barcode_cross_store_availability`, `mv_product_stock_summary` | 2-5 min | **Critical** (POS stock accuracy) |
| 05 | [Cash Register Sessions](./05_cash_register_session_materialized_view.md) | `mv_cash_register_session_summary`, `mv_cash_account_daily_flow` | 1-2 min | **Critical** (cash handling) |
| 06 | [Customer/Supplier AR/AP](./06_customer_supplier_ar_ap_materialized_view.md) | `mv_customer_ar_balance`, `mv_supplier_ap_balance`, `mv_customer_credit_status` | 15 min | **Medium** (AR/AP reports, credit checks) |
| 07 | [Product Movement](./07_product_movement_materialized_view.md) | `mv_product_daily_movement`, `mv_product_summary`, `mv_category_performance` | 30 min | **Medium** (analytics, reorder) |
| 08 | [Work Order Analytics](./08_work_order_analytics_materialized_view.md) | `mv_work_order_daily`, `mv_technician_performance`, `mv_work_order_category_performance` | 15 min | **Low** (technician dashboards) |

## Implementation Order (Recommended)

### Phase 1: Core POS Operations (Week 1-2)
1. **01 Inventory Reports** - Already has table structure, convert to MV
2. **04 Stock Balance** - Most critical for POS accuracy
3. **05 Cash Register Sessions** - Critical for cash handling

### Phase 2: Financial Reporting (Week 2-3)
4. **03 Sales Reports** - High visibility, cash reconciliation
5. **02 Accounting Financials** - Trial Balance, Income Statement

### Phase 3: Business Analytics (Week 3-4)
6. **06 Customer/Supplier AR/AP** - Credit management
7. **07 Product Movement** - Reorder, profitability
8. **08 Work Order Analytics** - Technician performance

## Shared Infrastructure Requirements

### 1. Refresh Scheduler
```ruby
# config/initializers/materialized_views.rb
# Use pg_cron (preferred) or Sidekiq-cron

# pg_cron example (run in migration):
# SELECT cron.schedule('refresh-inventory-reports', '*/5 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_inventory_reports;');
# SELECT cron.schedule('refresh-stock-balance', '*/2 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_stock_balance;');
# SELECT cron.schedule('refresh-cash-sessions', '* * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_cash_register_session_summary;');
```

### 2. Base Model for Materialized Views
```ruby
# app/models/materialized_view_record.rb
class MaterializedViewRecord < ApplicationRecord
  self.abstract_class = true

  # Materialized views are read-only
  def readonly?
    true
  end

  # Disable timestamps
  self.record_timestamps = false

  # Refresh method
  def self.refresh_concurrently!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY #{table_name}")
  end
end
```

### 3. Model Integration Pattern
```ruby
# app/models/inventory_report.rb (updated)
class InventoryReport < MaterializedViewRecord
  self.table_name = 'mv_inventory_reports'
  # ... existing associations work unchanged
end
```

### 4. Migration Template
```ruby
# db/migrate/xxxxxx_create_mv_inventory_reports.rb
class CreateMvInventoryReports < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW mv_inventory_reports AS
      -- ... (from PRD 01)
    SQL
    execute "CREATE UNIQUE INDEX idx_mv_inventory_reports_stock_id ON mv_inventory_reports(stock_id);"
    execute "CREATE INDEX idx_mv_inventory_reports_product_id ON mv_inventory_reports(product_id);"
    execute "CREATE INDEX idx_mv_inventory_reports_store_front_id ON mv_inventory_reports(store_front_id);"
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS mv_inventory_reports;"
  end
end
```

## Testing Strategy

### 1. Data Parity Tests
```ruby
# spec/models/mv_inventory_report_parity_spec.rb
RSpec.describe "InventoryReport MV Parity" do
  it "matches legacy table row-for-row" do
    legacy = InventoryReportLegacy.all.to_a
    mv = InventoryReport.all.to_a
    expect(mv.map(&:attributes)).to eq(legacy.map(&:attributes))
  end

  it "computed balance matches Stock#balance" do
    Stock.find_each do |stock|
      mv_report = InventoryReport.find_by(stock_id: stock.id)
      expect(mv_report.available).to eq(stock.balance)
    end
  end
end
```

### 2. Performance Benchmarks
```ruby
# spec/performance/materialized_views_spec.rb
RSpec.describe "Materialized View Performance" do
  it "inventory report CSV < 200ms" do
    expect { get :index, format: :csv, params: { store_front_id: store_front.id } }
      .to perform_under(200).ms
  end
end
```

## Rollback Plan

Each MV migration includes `down` method to drop the view. During transition:
1. Keep legacy table/model alongside MV
2. Dual-write: update both legacy and MV (or just MV with legacy reads)
3. Switch reads to MV one controller at a time
4. Drop legacy table after full verification

## Monitoring

### Key Metrics to Track
- **Refresh duration**: `pg_stat_progress_create_index` / custom logging
- **Staleness**: `now() - pg_stat_clear_snapshot()` for MV
- **Query performance**: `pg_stat_statements` for MV queries
- **Data parity**: Nightly job comparing MV vs live computation

### Alerting Rules
- Refresh duration > 60s → Alert
- Staleness > 2x refresh interval → Alert
- Row count delta > 5% between refreshes → Alert

## Dependencies & Prerequisites

1. **PostgreSQL Extensions**
   - `pg_cron` (for scheduling) - **Required**
   - `pg_stat_statements` (for monitoring) - **Recommended**

2. **Database Configuration**
   - `max_worker_processes` ≥ 8 (for parallel refresh)
   - `maintenance_work_mem` ≥ 256MB (for MV refresh)
   - `autovacuum` enabled on MV tables

3. **Application**
   - Sidekiq/Redis for job-based triggers (if not using pg_cron)
   - Read-only model base class
   - Feature flags for gradual rollout

## Contact
- **Owner**: Backend Team
- **Reviewers**: DevOps, DBA, QA
- **Target Completion**: 4 weeks from Phase 1 start