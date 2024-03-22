class StockTransfersController < AuthenticatedController
  def index
    @stock_transfers = StockTransfer.all.order(date: :desc).paginate(page: (params[:page]), per_page: 35)
  end
  def show
    @stock_transfer = StockTransfer.find(params[:id])
    respond_to do |format|
      format.html
      format.xls
      format.pdf do
        pdf = StockTransferPdf.new(@stock_transfer, view_context)
          send_data pdf.render, type: "application/pdf", disposition: 'inline', file_name: "Order.pdf"
      end
    end
  end
  def destroy
    @stock_transfer = StockTransfer.find(params[:id])
    @stock_transfer.destroy
    redirect_to branch_url(@stock_transfer.destination_branch), notice: "Stock transfer deleted successfully"
  end
end
