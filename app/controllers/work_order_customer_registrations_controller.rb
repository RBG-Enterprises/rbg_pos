class WorkOrderCustomerRegistrationsController < ApplicationController
	def new
		@customer = Customer.new
	end
  def create
    @customer = Customer.create(customer_params)
    AccountCreators::Customer.new(customer: @customer).create_accounts! if @customer.persisted?
    respond_to do |format|
      format.html { redirect_to new_computer_repair_section_work_order_url(customer_id: @customer.id), notice: 'Customer saved successfully' }
      format.js
    end
  end
  
	private
	def customer_params
		params.require(:customer).permit(:first_name, :last_name, :address, :contact_number, :business_id)
	end
end
