module RepairServices
  class PerEmployeeDashboardsController < ApplicationController
    def index
      @from_date          = params[:from_date] ? Date.parse(params[:from_date]) : Date.current.beginning_of_month
      @to_date            = params[:to_date]   ? Date.parse(params[:to_date])   : Date.current.end_of_month
      @employee           = User.find(params[:user_id])
      @pagy, @work_orders = pagy(@employee.work_orders.released_on(from_date: @from_date, to_date: @to_date))

      authorize [:repair_services, :per_employee_dashboards]

      respond_to do |format|
        format.html
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
      headers["Content-Disposition"] = "attachment; filename=\"Repairs.csv\""

      # Don't buffer when going through proxy servers
      headers["X-Accel-Buffering"] = "no"

      # Set an Enumerator as the body
      self.response_body = csv_body

      response.status = 200
    end

    private

    def csv_body
      Enumerator.new do |yielder|
        yielder << CSV.generate_line(["Work Order", "Service #", "Date Released", "Customer", "Service Charges", "Spare Parts"])

        @employee.work_orders.released_on(from_date: @from_date, to_date: @to_date).each do |work_order|
          yielder << CSV.generate_line([
            work_order.product_unit.description,
            work_order.service_number,
            work_order.release_date.try(:strftime, ('%B %e, %Y')),
            work_order.customer.full_name,
            work_order.service_revenue_account.balance,
            work_order.sales_revenue_account.balance
            ])
        end
      end
    end
  end
end
