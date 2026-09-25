class VouchersController < ApplicationController
  def index
    @vouchers = Voucher.all.order(date: :desc).paginate(page: params[:page], per_page: 35)
  end
  def show
    @voucher = Voucher.find(params[:id])
  end

  def destroy
    @voucher = Voucher.find(params[:id])
    Vouchers::Cancellation.run(voucher: @voucher)
    redirect_to safe_return_to(vouchers_path), notice: "Voucher cancelled."
  end
end
