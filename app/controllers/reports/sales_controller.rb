module Reports
	class SalesController < ApplicationController
		def index
			@from_date = Chronic.parse(params[:from_date].to_date)
      @to_date = Chronic.parse(params[:to_date].to_date)
      @store_front = StoreFront.find_by(id: params[:store_front_id])
      @employee = params[:user_id] ? User.find(params[:user_id]) : current_user
      if !current_user.proprietor?
        @orders = current_user.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date)
      elsif @store_front.present?
        @orders = @store_front.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date)
      else
			  @orders = StoreFrontModule::Orders::SalesOrder.ordered_on(from_date: @from_date, to_date: @to_date)
      end
			respond_to do |format|
        format.xlsx
				format.pdf do
					pdf = Reports::SalesPdf.new(
            from_date:    @from_date,
            to_date:      @to_date,
            orders:       @orders,
            business:     current_business,
            store_front: @store_front,
            cash_on_hand_account: @employee.cash_on_hand_account,
            employee:     @employee,
            view_context: view_context)
					send_data pdf.render, type: 'application/pdf', disposition: 'inline', file_name: 'Sales Report.pdf'
		    end
		  end
		end
	end
end
