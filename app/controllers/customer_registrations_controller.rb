class CustomerRegistrationsController < AuthenticatedController
	def new
		@customer = Customer.new
	end
	def create
		@customer = Customer.create(customer_params)
    AccountCreators::Customer.new(customer: @customer).create_accounts!
	end
	private
	def customer_params
		params.require(:customer).permit(:first_name, :last_name, :address, :contact_number, :business_id)
	end
end
