module ComputerRepairSection
  class DashboardController < AuthenticatedController
    def index
      @from_date = params[:from_date] || DateTime.now.beginning_of_month
      @to_date   = params[:to_date] || DateTime.now.end_of_month
      if params[:technician].present?
        @technician = User.find(params[:technician])
       @pagy, @work_orders = pagy(@technician.work_orders.order(created_at: :desc).includes(:product_unit, :customer, :charge_invoice, :technician_work_orders, :store_front, :technicians =>[:avatar_attachment =>[:blob]]))
      elsif params[:search].present?
        @pagy, @work_orders = pagy(current_business.work_orders.order(created_at: :desc).includes(:product_unit, :customer, :charge_invoice, :technician_work_orders, :store_front, :technicians =>[:avatar_attachment =>[:blob]]).text_search(params[:search]))
      elsif params[:section_id].present?
        @pagy, @work_orders = pagy(Section.find(params[:section_id]).work_orders.order(created_at: :desc).includes(:product_unit, :customer, :charge_invoice, :technician_work_orders, :store_front, :technicians =>[:avatar_attachment =>[:blob]]))
      else
        @pagy, @work_orders = pagy(current_business.work_orders.order(created_at: :desc).includes(:product_unit, :customer, :charge_invoice, :technician_work_orders, :store_front, :technicians =>[:avatar_attachment =>[:blob]]))
      end
      @pagy, @received_work_orders = pagy(current_business.work_orders.received.order(created_at: :desc))
      @pagy, @work_in_progress_work_orders = pagy(current_business.work_orders.work_in_progress.order(created_at: :desc))
      @pagy, @released_work_orders = pagy(current_business.work_orders.released.order(created_at: :desc))
      @pagy, @done_and_rto_work_orders = pagy(current_business.work_orders.done_and_rto.order(created_at: :desc))
    end
  end
end
