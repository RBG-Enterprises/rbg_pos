class OtherSalesController < ApplicationController
  before_action :require_open_cash_register_session, only: [:new, :create]

  def new
    @other_sale = OtherSalesForm.new
    if params[:customer_search].present?
      @customers = current_business.customers.text_search(params[:customer_search]).limit(8)
    end
  end
  def create
    @other_sale = OtherSalesForm.new(other_sale_params.merge(cash_register_session_id: current_cash_register_session.try(:id)))
    if @other_sale.valid?
      order = nil
      ActiveRecord::Base.transaction do
        @other_sale.process!
        order = @other_sale.find_order
        create_voucher(order)
      end
      redirect_to other_sale_path(order.voucher), notice: "Review and confirm the sale."
    else
      render :new
    end
  end

  def show
    @voucher = Voucher.find(params[:id])
    @order = @voucher.commercial_document
  end

  private

  def require_open_cash_register_session
    return if cash_register_session_open?

    redirect_to store_index_url, alert: "Declare your opening cash float before recording an other sale."
  end

  def other_sale_params
    params.require(:other_sales_form).permit(:recorder_id, :amount, :reference_number, :description, :date, :recorder_id, :customer_id, :account_number)
  end

  def create_voucher(order)
    Vouchers::OtherSalesOrderVoucher.new(order: order, employee: order.employee, amount: params[:other_sales_form][:amount]).create_voucher!
  end
end
