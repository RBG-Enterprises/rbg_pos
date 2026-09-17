require 'csv'
module StoreFrontModule
  module StoreFronts
    class WorkOrderPaymentsController < ApplicationController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @from_date = params[:from_date].present? ? Date.parse(params[:from_date]) : Date.current.beginning_of_month
        @to_date = params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current.end_of_month
        respond_to do |format|
          format.csv { render_csv }
        end
      end

      private

      def render_csv
        headers.delete("Content-Length")
        headers["Cache-Control"] = "no-cache"
        headers["Content-Type"] = "text/csv"
        headers["Content-Disposition"] = "attachment; filename=\"Service Payments.csv\""
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
          yielder << CSV.generate_line(["Date", "Customer", "Service #", "Description", "Amount", "Technician", "Employee"])

          total = 0
          store_front.work_orders.payment_entries.entered_on(from_date: from_date, to_date: to_date).find_each do |entry|
            work_order = WorkOrder.find_by(receivable_account_id: entry.credit_amounts.pluck(:account_id))
            yielder << CSV.generate_line([
              entry.entry_date,
              work_order.customer.name,
              work_order.service_number,
              entry.description,
              entry.total,
              work_order.technicians.map { |a| a.full_name }.join(","),
              entry.recorder_name
            ])
            total += entry.total
          end

          yielder << CSV.generate_line(["", "", "", "TOTAL", total])
        end
      end
    end
  end
end
