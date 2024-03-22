module Stocks
	class TransfersController < AuthenticatedController
		def new
			@stock = Stock.find(params[:stock_id])
			@transfer = @stock.stock_transfers.build
			authorize @transfer
		end
		def create
			@stock = Stock.find(params[:stock_id])
			@transfer = @stock.stock_transfers.create(transfer_params)
			authorize @transfer
			@transfer.origin_branch = @stock.branch
			if @transfer.valid?
				@transfer.save
				redirect_to @stock, notice: "Stock transfer saved successfully."
			else
				render :new
			end
		end

		private
		def transfer_params
			params.require(:stock_transfer).permit(:quantity, :date, :destination_branch_id)
		end
	end
end
