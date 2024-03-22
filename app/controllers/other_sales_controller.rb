class OtherSalesController < AuthenticatedController
  def new
    @other_sale = OtherSalesForm.new
  end
  def create
    @other_sale = OtherSalesForm.new(other_sale_params)
    if @other_sale.valid?
      ActiveRecord::Base.transaction do
        @other_sale.process!
        create_voucher(@other_sale.find_order)
        create_entry(@other_sale.find_order)
        redirect_to store_index_url, notice: "Other Sales saved successfully"
      end
    else
      render :new
    end
  end

  private

  def other_sale_params
    params.require(:other_sales_form).permit(:recorder_id, :amount, :reference_number, :description, :date, :recorder_id, :customer_id, :account_number)
  end

  def create_voucher(order)
    Vouchers::OtherSalesOrderVoucher.new(order: order, employee: order.employee, amount: params[:other_sales_form][:amount]).create_voucher!
  end

  def create_entry(order)
    VoucherEntryCreation.new(voucher: order.voucher).create_entry!
  end
end
