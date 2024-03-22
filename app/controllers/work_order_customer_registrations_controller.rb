class WorkOrderCustomerRegistrationsController < AuthenticatedController
	def new
		@customer = Customer.new
	end
  def create
    @customer = Customer.create(customer_params)
    if @customer.valid?
      @customer.save!
      AccountCreators::Customer.new(customer: @customer).create_accounts!
      redirect_to new_computer_repair_section_work_order_url(customer_id: @customer.id), notice: 'Customer saved successfully'
    else
      render :new
    end
  end

	private
	def customer_params
		params.require(:customer).permit(:first_name, :last_name, :address, :contact_number, :business_id)
	end
end
