require 'csv'
module StoreFrontModule
  module StoreFronts
    class WorkOrdersController < ApplicationController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @service_receiveable_account_category = @store_front.service_receivable_account_category
        @all_work_orders = @store_front.work_orders
        @from_date = params[:from_date].present? ? Date.parse(params[:from_date]) : Date.current.beginning_of_month
        @to_date = params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current.end_of_month
        @pagy, @work_orders = pagy(@store_front.work_orders)
        respond_to do |format|
          format.html
          format.csv { render_csv }
        end
      end

      private

      def render_csv
        headers.delete("Content-Length")
        headers["Cache-Control"] = "no-cache"
        headers["Content-Type"] = "text/csv"
        headers["Content-Disposition"] = "attachment; filename=\"Repair Services.csv\""
        headers["X-Accel-Buffering"] = "no"
        signal_report_download_started
        self.response_body = csv_body
        response.status = 200
      end

      def csv_body
        store_front = @store_front
        from_date   = @from_date
        to_date     = @to_date

        Enumerator.new do |yielder|
          yielder << CSV.generate_line(["Service Number", "Customer", "Product", "Reported Problem", "Status", "Date Received", "Technicians"])

          store_front.work_orders.received_at(from_date: from_date, to_date: to_date).find_each do |work_order|
            yielder << CSV.generate_line([
              work_order.service_number,
              work_order.customer_name,
              work_order.product_name,
              work_order.reported_problem,
              work_order.status.humanize,
              work_order.date_received,
              work_order.technicians.map { |a| a.full_name }.join(",")
            ])
          end
        end
      end
    end
  end
end
