class DashboardController < AuthenticatedController
	def index
    @employees = User.all
    @business = current_user.business
    @sales_for_today = StoreFrontModule::Orders::SalesOrder.ordered_on(from_date: Date.today, to_date: Date.today)
	end
end
