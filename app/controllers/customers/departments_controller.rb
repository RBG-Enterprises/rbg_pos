module Customers
  class DepartmentsController < AuthenticatedController
    def new
      @customer = Customer.find(params[:customer_id])
      @department = @customer.departments.build
    end
    def create
      @customer = Customer.find(params[:customer_id])
      @department = @customer.departments.create(department_params)
      if @department.valid?
        @department.save!
        redirect_to customer_settings_url(@customer), notice: 'Department created successfully'
      else
        render :new
      end
    end

    private
    def department_params
      params.require(:department).
      permit(:name)
    end
  end
end
