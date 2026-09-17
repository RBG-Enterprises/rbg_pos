require 'rqrcode'

class WorkOrdersController < ApplicationController
  def index
    @from_date = DateTime.parse(params[:from_date])
    @to_date = DateTime.parse(params[:to_date])
    @work_orders = WorkOrder.from(from_date: @from_date, to_date: @to_date).order(created_at: :desc)
    respond_to do |format|
      format.html
      format.pdf do
        pdf = WorkOrderPdf.new(@work_orders, @from_date, @to_date, view_context)
        send_data pdf.render, type: "application/pdf", disposition: 'inline', file_name: "Work Order.pdf"
      end
      format.csv { render_csv }
    end
  end
  def new
    @work_order = WorkOrderForm.new
  end
  def create
    @work_order = WorkOrderForm.new(work_order_params)
    if @work_order.valid?
      @work_order.save
      redirect_to work_orders_url, notice: "Work Order saved successfully."
    else
      render :new
    end
  end


  private
  def work_order_params
    params.require(:work_order_form).permit(:description, :model_number, :serial_number, :physical_condition, :reported_problem)
  end

  def render_csv
    headers.delete("Content-Length")
    headers["Cache-Control"] = "no-cache"
    headers["Content-Type"] = "text/csv"
    headers["Content-Disposition"] = "attachment; filename=\"Work Order.csv\""
    headers["X-Accel-Buffering"] = "no"

    self.response_body = csv_body

    response.status = 200
  end

  def csv_body
    Enumerator.new do |yielder|
      yielder << CSV.generate_line([
        "DATE",
        "CUSTOMER",
        "#",
        "UNIT",
        "STATUS",
        "REPORTED PROBLEM",
        "TECHNICIANS",
        "SPARE PARTS",
        "CHARGES",
        "TOTAL COST",
        "RECEIVED DATE",
        "RELEASE DATE",
        "DONE DATE",
      ])
      @work_orders.each do |work_order|
        yielder << CSV.generate_line([
          work_order.created_at.strftime("%B %e, %Y"),
          work_order.customer_name,
          work_order.service_number,
          work_order.product_unit.try(:description),
          work_order.status.try(:titleize),
          work_order.reported_problem,
          work_order.technicians_name,
          work_order.total_spare_parts_cost,
          work_order.total_service_charges_cost,
          work_order.total_charges_cost,
          work_order.date_received.try(:strftime, "%B %e, %Y"),
          work_order.release_date.try(:strftime, "%B %e, %Y"),
          work_order.done_at.try(:strftime, "%B %e, %Y"),
        ])
      end
      yielder << CSV.generate_line([
        "", "", "", "", "", "", "",
        @work_orders.total_spare_parts_cost(from_date: @from_date, to_date: @to_date),
        @work_orders.total_service_charges_cost(from_date: @from_date, to_date: @to_date),
        @work_orders.total_charges_cost(from_date: @from_date, to_date: @to_date),
        "",
        "",
        "",
      ])
    end
  end
end
