module Reports
  class PurchaseReturnsController < AuthenticatedController
    def index
      @from_date = Chronic.parse(params[:from_date].to_date)
      @to_date = Chronic.parse(params[:to_date].to_date)
      @employee = User.find_by(id: params[:user_id])
      if @employee.present?
        @orders = @employee.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date)
      else
			  @orders = StoreFrontModule::Orders::PurchaseReturnOrder.ordered_on(from_date: @from_date, to_date: @to_date)
      end
			respond_to do |format|
        format.xlsx
      end
    end
  end
end
