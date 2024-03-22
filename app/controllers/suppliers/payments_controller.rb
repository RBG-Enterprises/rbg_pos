module Suppliers
  class PaymentsController < AuthenticatedController
    def new
     @supplier = Supplier.find(params[:supplier_id])
      @entry = AccountingModule::SupplierPaymentForm.new
    end
    def create
      @supplier = Supplier.find(params[:supplier_id])
      @entry = AccountingModule::SupplierPaymentForm.new(entry_params)
      if @entry.valid?
        @entry.save
        redirect_to @supplier, notice: "Payment saved successfully."
      else
        render :new
      end
    end

    private
    def entry_params
      params.require(:accounting_module_supplier_payment_form).permit(:user_id, :supplier_id, :entry_date, :reference_number, :description, :credit_account_id, :amount)
    end
  end
end
