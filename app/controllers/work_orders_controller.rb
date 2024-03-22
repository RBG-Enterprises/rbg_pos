require 'rqrcode'

class WorkOrdersController < AuthenticatedController
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
end
