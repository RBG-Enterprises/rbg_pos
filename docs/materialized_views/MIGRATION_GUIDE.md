# Materialized View Migration Guide

## Quick Start Checklist

### Prerequisites
- [ ] PostgreSQL 12+ with `pg_cron` extension installed
- [ ] `pg_stat_statements` enabled for monitoring
- [ ] Maintenance window identified for initial MV creation
- [ ] Backup strategy verified

### Per-PRD Implementation Steps

For each PRD (01-08), follow this pattern:

```
1. Create migration with MV definition
2. Create read-only model extending MaterializedViewRecord
3. Add refresh job (pg_cron or Sidekiq)
4. Write parity tests (old vs new)
5. Switch one controller at a time
6. Monitor for 48 hours
7. Drop legacy table/code
```

---

## Detailed Implementation: PRD 01 (Inventory Reports)

### Step 1: Migration
```bash
bin/rails generate migration CreateMvInventoryReports
```

```ruby
# db/migrate/20261001000000_create_mv_inventory_reports.rb
class CreateMvInventoryReports < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
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
        WHERE type = 'StoreFrontModule::LineItems::PurchaseOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) purchases ON purchases.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::SalesOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) sales ON sales.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::SpoilageOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) spoilage ON spoilage.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::InternalUseOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) internal_use ON internal_use.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::StockTransferOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) transfers ON transfers.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::SalesReturnOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) sales_returns ON sales_returns.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::PurchaseReturnOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) purchase_returns ON purchase_returns.stock_id = s.id
      LEFT JOIN (
        SELECT stock_id, SUM(quantity) AS qty
        FROM line_items
        WHERE type = 'StoreFrontModule::LineItems::ForWarrantyOrderLineItem' AND order_id IS NOT NULL
        GROUP BY stock_id
      ) for_warranties ON for_warranties.stock_id = s.id
      WHERE s.is_processed = true;
    SQL

    # Required for CONCURRENTLY refresh
    execute "CREATE UNIQUE INDEX idx_mv_inventory_reports_stock_id ON mv_inventory_reports(stock_id);"
    execute "CREATE INDEX idx_mv_inventory_reports_product_id ON mv_inventory_reports(product_id);"
    execute "CREATE INDEX idx_mv_inventory_reports_store_front_id ON mv_inventory_reports(store_front_id);"
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS mv_inventory_reports;"
  end
end
```

### Step 2: Base Model
```ruby
# app/models/materialized_view_record.rb
class MaterializedViewRecord < ApplicationRecord
  self.abstract_class = true

  def readonly?
    true
  end

  self.record_timestamps = false

  def self.refresh_concurrently!
    connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY #{table_name}")
  rescue ActiveRecord::StatementInvalid => e
    # Handle case where unique index missing
    raise unless e.message.include?("cannot refresh materialized view")
    connection.execute("REFRESH MATERIALIZED VIEW #{table_name}")
  end
end
```

### Step 3: Updated Model
```ruby
# app/models/inventory_report.rb (replace existing)
class InventoryReport < MaterializedViewRecord
  self.table_name = 'mv_inventory_reports'

  belongs_to :stock, class_name: "StoreFronts::Stock"
  belongs_to :product
  belongs_to :store_front, class_name: "StoreFront"
  belongs_to :branch, class_name: "StoreFront", foreign_key: "store_front_id"

  validates :stock_id, presence: true, uniqueness: true
  validates :product_id, presence: true
  validates :store_front_id, presence: true

  def branch_id
    store_front_id
  end

  def branch_id=(value)
    self.store_front_id = value
  end
end
```

### Step 4: Refresh Job (if not using pg_cron)
```ruby
# app/jobs/refresh_inventory_reports_job.rb
class RefreshInventoryReportsJob < ApplicationJob
  queue_as :low_priority

  def perform
    InventoryReport.refresh_concurrently!
    Rails.logger.info "Refreshed mv_inventory_reports at #{Time.current}"
  rescue => e
    Rails.logger.error "Failed to refresh mv_inventory_reports: #{e.message}"
    raise
  end
end
```

### Step 5: pg_cron Setup (Run Once)
```sql
-- Run in psql or migration
SELECT cron.schedule(
  'refresh-mv-inventory-reports',
  '*/5 * * * *',  -- Every 5 minutes
  'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_inventory_reports;'
);

-- Verify
SELECT * FROM cron.job WHERE jobname = 'refresh-mv-inventory-reports';
```

### Step 6: Parity Test
```ruby
# spec/models/mv_inventory_report_parity_spec.rb
require 'rails_helper'

RSpec.describe "InventoryReport MV Parity", :aggregate_failures do
  let!(:stock) { create(:stock, :processed, count_adjustment: 5) }
  let!(:purchase) { create(:purchase_order_line_item, stock: stock, quantity: 100) }
  let!(:sale) { create(:sales_order_line_item, stock: stock, quantity: 30) }

  before do
    # Run legacy rebuilder
    InventoryReportRebuilder.call
    # Refresh MV
    InventoryReport.refresh_concurrently!
  end

  it "has same row count" do
    expect(InventoryReport.count).to eq(InventoryReportLegacy.count)
  end

  it "matches legacy data" do
    legacy = InventoryReportLegacy.find_by(stock_id: stock.id)
    mv = InventoryReport.find_by(stock_id: stock.id)

    expect(mv.purchases).to eq(legacy.purchases)
    expect(mv.sales).to eq(legacy.sales)
    expect(mv.available).to eq(legacy.available)
    expect(mv.available).to eq(stock.balance) # Source of truth
  end
end
```

### Step 7: Controller Switch
```ruby
# app/controllers/store_front_module/store_fronts/inventories_controller.rb
# Change line 18 from:
# @reports = @store_front.inventory_reports.includes(:product, :stock).order(:id)
# To (no change needed - same association):
@reports = @store_front.inventory_reports.includes(:product, :stock).order(:id)
```

### Step 8: Verify & Drop Legacy
```bash
# After 48 hours monitoring:
bin/rails runner "InventoryReportLegacy.delete_all"
# Then drop table in migration
```

---

## Common Patterns for All PRDs

### Pattern: Read-Only Model
```ruby
class MvAccountBalance < MaterializedViewRecord
  self.table_name = 'mv_account_balances'
  # No timestamps, no writes
end
```

### Pattern: Scoped Queries
```ruby
class MvAccountBalance < MaterializedViewRecord
  scope :for_business, ->(business_id) { where(business_id: business_id) }
  scope :date_range, ->(from, to) { where(balance_date: from..to) }
  scope :by_type, ->(*types) { where(account_type: types) }
end
```

### Pattern: Refresh with Logging
```ruby
class RefreshMvJob < ApplicationJob
  def perform(view_name)
    start = Time.current
    view_name.constantize.refresh_concurrently!
    duration = Time.current - start
    Rails.logger.info "[MV Refresh] #{view_name} completed in #{duration.round(2)}s"
  rescue => e
    Rails.logger.error "[MV Refresh] #{view_name} failed: #{e.message}"
    notify_error(e, view_name: view_name)
    raise
  end
end
```

### Pattern: Feature Flag Rollout
```ruby
# config/initializers/materialized_views.rb
MATERIALIZED_VIEWS_ENABLED = {
  inventory_reports: true,
  stock_balance: ENV['MV_STOCK_BALANCE'] == 'true',
  sales_reports: ENV['MV_SALES_REPORTS'] == 'true',
  # ...
}.freeze

# In controller:
def inventory_reports
  if MATERIALIZED_VIEWS_ENABLED[:inventory_reports]
    @reports = InventoryReport.where(...)
  else
    @reports = legacy_computation(...)
  end
end
```

---

## Troubleshooting

### Issue: "cannot refresh materialized view concurrently"
**Cause**: Missing unique index on MV
**Fix**: Add unique index on primary key column(s)

### Issue: Refresh takes too long / locks
**Cause**: Large MV, no concurrent index
**Fix**: 
- Ensure unique index exists
- Increase `maintenance_work_mem`
- Consider partitioning for very large MVs

### Issue: Stale data in reports
**Cause**: Refresh job not running / failing
**Fix**: 
- Check pg_cron job status: `SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;`
- Check Sidekiq queue latency
- Add monitoring alert on staleness

### Issue: Data mismatch between MV and live
**Cause**: 
- Different date boundaries (timezone)
- Missing `order_id IS NOT NULL` filter
- Contra account logic
**Fix**: Compare query logic line-by-line, add parity tests

---

## Performance Tuning

### For Large MVs (>100k rows)
```sql
-- Enable parallel refresh
SET max_parallel_maintenance_workers = 4;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_large_view;

-- Or partition by date
CREATE MATERIALIZED VIEW mv_product_daily_movement_partitioned
PARTITION BY RANGE (movement_date) AS
SELECT ... FROM ...;
```

### Index Strategy
- Always have unique index for `CONCURRENTLY`
- Add indexes matching query patterns (see each PRD)
- Monitor with `pg_stat_user_indexes`

### Refresh Scheduling
- Stagger refreshes to avoid concurrent load
- Heavy MVs (accounting, product movement): off-peak or hourly
- Critical MVs (stock, cash): every 2-5 min

---

## Rollback Procedure

```bash
# 1. Disable feature flag
export MV_INVENTORY_REPORTS=false

# 2. Restore legacy table if dropped
# (from backup or re-run legacy migration)

# 3. Re-enable legacy code path
# (controllers already have fallback)

# 4. Drop MV
bin/rails runner "ActiveRecord::Base.connection.execute('DROP MATERIALIZED VIEW mv_inventory_reports')"
```

---

## Sign-Off Checklist Per PRD

- [ ] Migration created and tested on staging
- [ ] Read-only model created
- [ ] Refresh job scheduled (pg_cron verified)
- [ ] Parity tests passing (100% match)
- [ ] Performance benchmarks met
- [ ] One controller switched and verified
- [ ] All controllers switched
- [ ] Legacy code removed
- [ ] Monitoring alerts configured
- [ ] Documentation updated