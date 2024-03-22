module Customers
  class RepairServicesController < AuthenticatedController
    def index
      @customer = Customer.find(params[:customer_id])
      @repair_services = @customer.work_orders.order(created_at: :desc).all.paginate(page: params[:page], per_page: 35)
    end
  end
end
