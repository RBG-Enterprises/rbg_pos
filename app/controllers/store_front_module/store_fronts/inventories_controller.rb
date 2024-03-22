require 'csv'
module StoreFrontModule
  module StoreFronts
    class InventoriesController < AuthenticatedController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @stocks      = @store_front.stocks.processed
        respond_to do |format|
          format.html
          format.xlsx
          format.csv { render_csv }
        end
      end

      private
      def render_csv
        # Tell Rack to stream the content
        headers.delete("Content-Length")

        # Don't cache anything from this generated endpoint
        headers["Cache-Control"] = "no-cache"

        # Tell the browser this is a CSV file
        headers["Content-Type"] = "text/csv"

        # Make the file download with a specific filename
        headers["Content-Disposition"] = "attachment; filename=\"Stock Inventory.csv\""

        # Don't buffer when going through proxy servers
        headers["X-Accel-Buffering"] = "no"

        # Set an Enumerator as the body
        self.response_body = csv_body

        response.status = 200
      end

      private

      def csv_body
        Enumerator.new do |yielder|
          yielder << CSV.generate_line(["Name", "Barcode", "Purchases", "Sales", "Stock Transfers", "Spoilages", "Internal Uses", 'Sales Returns', 'For Warranty', "Available QTY"])

          @stocks.joins(:product).order('products.name').each do |stock|
            yielder << CSV.generate_line([
              stock.name,
              stock.barcode.to_s,
              stock.purchase_quantity,
              stock.sales_balance,
              stock.stock_transfers_balance,
              stock.spoilages_balance,
              stock.internal_uses_balance,
              stock.sales_returns_balance,
              stock.for_warranties_balance,
              stock.available_quantity
              ])
          end
        end
      end
    end
  end
end
