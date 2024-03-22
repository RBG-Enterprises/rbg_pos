class AccountingController < AuthenticatedController
	def index
		@entries = AccountingModule::Entry.all.order(entry_date: :desc).paginate(page: params[:page], per_page: 35)
    @expenses = AccountingModule::Entry.expense.all.order(entry_date: :desc).paginate(page: params[:page], per_page: 35)
	end
end
