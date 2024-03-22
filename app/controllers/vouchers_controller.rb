class VouchersController < AuthenticatedController
  def index
    @vouchers = Voucher.all.order(date: :desc).paginate(page: params[:page], per_page: 35)
  end
  def show
    @voucher = Voucher.find(params[:id])
  end
end
