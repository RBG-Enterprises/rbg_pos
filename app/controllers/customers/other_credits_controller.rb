module Customers
  class OtherCreditsController < AuthenticatedController
    def new
      @customer = Customer.find(params[:customer_id])
      @other_credit = Customers::OtherCredit.new
    end

    def create
      @customer = Customer.find(params[:customer_id])
      @other_credit =Customers::OtherCredit.new(credit_params)
      if @other_credit.valid?
        @other_credit.process!
        redirect_to customer_url(@customer), notice: "saved successfully"
      else
        render :new
      end
    end

    private
    def credit_params
      params.require(:customers_other_credit).permit(:customer_id, :amount, :description, :reference_number, :date, :employee_id)
    end
  end
end
