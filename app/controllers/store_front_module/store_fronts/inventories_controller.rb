# frozen_string_literal: true

require "csv"
module StoreFrontModule
  module StoreFronts
    class InventoriesController < ApplicationController
      LINE_ITEMS = "StoreFrontModule::LineItems"

      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @as_of_date  = params[:as_of_date].present? ? Date.parse(params[:as_of_date]) : Date.current
        @stocks      = @store_front.stocks.processed.joins(:product).includes(:product).order("products.name")

        respond_to do |format|
          format.html
          format.xlsx { load_xlsx_balances }
          format.csv do
            @reports = @store_front.inventory_reports.includes(:product, :stock).order(:id)
            render_inventory_csv
          end
        end
      end

      private

      # CSV is served from the prebuilt InventoryReport table (rebuilt
      # periodically by InventoryReportRebuilder), never aggregated live
      # from LineItem history.
      def render_inventory_csv
        # Tell Rack to stream the content
        headers.delete("Content-Length")

        # Don't cache anything from this generated endpoint
        headers["Cache-Control"] = "no-cache"

        # Tell the browser this is a CSV file
        headers["Content-Type"] = "text/csv"

        # Make the file download with a specific filename
        headers["Content-Disposition"] = "attachment; filename=\"inventory-report-#{Date.current.strftime('%Y-%m-%d')}.csv\""

        # Don't buffer when going through proxy servers
        headers["X-Accel-Buffering"] = "no"

        signal_report_download_started

        # Set an Enumerator as the body
        self.response_body = inventory_csv_body

        response.status = 200
      end

      def inventory_csv_body
        reports = @reports

        Enumerator.new do |yielder|
          yielder << CSV.generate_line([
            "Product",
            "SKU",
            "Purchases",
            "Sales",
            "Spoilage",
            "Internal Use",
            "Transfers",
            "Sales Returns",
            "Purchase Returns",
            "For Warranty",
            "Adjustment",
            "Available",
          ])

          # One row per Stock; the same Product appears on multiple rows
          # when it has multiple Stocks/SKUs.
          reports.each do |report|
            yielder << CSV.generate_line([
              report.product&.name,
              report.stock&.barcode.to_s,
              csv_number(report.purchases),
              csv_number(report.sales),
              csv_number(report.spoilage),
              csv_number(report.internal_use),
              csv_number(report.transfers),
              csv_number(report.sales_returns),
              csv_number(report.purchase_returns),
              csv_number(report.for_warranties),
              csv_number(report.stock&.count_adjustment),
              csv_number(report.available),
            ])
          end
        end
      end

      def csv_number(value)
        return 0 if value.nil?

        value == value.to_i ? value.to_i : value.to_f
      end

      # Same idea for the xlsx sheet, which reports unfiltered (not processed-only,
      # not date-bound) balances via stock.sales.balance etc, and includes Purchase
      # Returns instead of Sales Returns / For Warranty.
      def load_xlsx_balances
        stock_ids = @stocks.pluck(:id)

        opts = { processed_only: false }
        @purchase_quantities    = first_quantity_by_stock("#{LINE_ITEMS}::PurchaseOrderLineItem", stock_ids)
        @sales_balances         = balances_by_stock("#{LINE_ITEMS}::SalesOrderLineItem", stock_ids, **opts)
        @stock_transfer_balances = balances_by_stock("#{LINE_ITEMS}::StockTransferOrderLineItem", stock_ids, **opts)
        @spoilage_balances      = balances_by_stock("#{LINE_ITEMS}::SpoilageOrderLineItem", stock_ids, **opts)
        @internal_use_balances  = balances_by_stock("#{LINE_ITEMS}::InternalUseOrderLineItem", stock_ids, **opts)
        @purchase_return_balances = balances_by_stock("#{LINE_ITEMS}::PurchaseReturnOrderLineItem", stock_ids, **opts)
      end

      def balances_by_stock(type, stock_ids, processed_only: true, up_to: nil)
        return {} if stock_ids.empty?

        scope = LineItem.where(type: type, stock_id: stock_ids)
        scope = scope.where.not(order_id: nil) if processed_only
        scope = scope.joins(:order).where("orders.date" => ..up_to) if up_to
        scope.group(:stock_id).sum(:quantity)
      end

      # Mirrors Stock#purchase (has_one, no explicit order -> lowest id wins) without
      # querying per stock.
      def first_quantity_by_stock(type, stock_ids)
        return {} if stock_ids.empty?

        rows = LineItem.where(type: type, stock_id: stock_ids).order(:id).pluck(:stock_id, :quantity)
        rows.group_by(&:first).transform_values { |group| group.first.last }
      end
    end
  end
end
