class CustomersController < ApplicationController
	def index
		if params[:search].present?
			@pagy, @customers = pagy(current_business.customers.includes(:orders, :work_orders, :avatar_attachment =>[:blob]).text_search(params[:search]))
		else
			@pagy, @customers = pagy(current_business.customers.includes(:orders, :work_orders, :avatar_attachment =>[:blob]))
		end
	end
	def new
		@customer = Customer.new
	end
	def create
		@customer = Customer.create(customer_params)
		if @customer.valid?
			@customer.save
      AccountCreators::Customer.new(customer: @customer).create_accounts!
			redirect_to customers_url, notice: "Customer saved successfully"
		else
			render :new
		end
	end
	def show
		@customer = Customer.find(params[:id])
	end
  def edit
    @customer = Customer.find(params[:id])
  end
  def update
    @customer = Customer.find(params[:id])
    @customer.update(customer_params)
    if @customer.valid?
      @customer.save
      redirect_to @customer, notice: 'Customer information updated successfully.'
    else
      render :edit
    end
  end
  def destroy
    @customer = Customer.find(params[:id])
    @customer.destroy
    redirect_to customers_url, alert: "Customer destroyed successfully"
  end

  # Proprietor-only: void a payment on the customer's account tab by
  # posting a reversal entry (never deletes the original).
  def void_payment
    @customer = Customer.find(params[:id])
    unless current_user.proprietor?
      redirect_to customer_account_index_path(@customer),
                  alert: "Only proprietors can void payments."
      return
    end

    entry = AccountingModule::Entry.find(params[:entry_id])
    Customers::VoidPayment.call(customer: @customer, entry: entry, current_user: current_user, note: params[:void_note])
    redirect_to customer_account_index_path(@customer),
                notice: "Payment voided successfully."
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_account_index_path(@customer),
                alert: "Payment not found for this customer."
  rescue Customers::VoidPayment::NotVoidable => e
    redirect_to customer_account_index_path(@customer), alert: e.message
  end

	private
	def customer_params
		params.require(:customer).permit(:first_name, :last_name, :contact_number, :address, :business_id, :avatar)
	end
end
