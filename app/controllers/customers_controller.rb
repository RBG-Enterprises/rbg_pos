class CustomersController < AuthenticatedController
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

	private
	def customer_params
		params.require(:customer).permit(:first_name, :last_name, :contact_number, :address, :business_id, :avatar)
	end
end
