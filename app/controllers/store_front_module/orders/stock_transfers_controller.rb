module StoreFrontModule
  module Orders
    class StockTransfersController < ApplicationController
      def index
        if params[:store_front_id].present?
          @pagy, @stock_transfer_orders = pagy(StoreFront.find(params[:store_front_id]).received_stock_transfer_orders)
        elsif params[:from_date] && params[:to_date]
          @pagy, @stock_transfer_orders = pagy(StoreFrontModule::Orders::PurchaseOrder.stock_transfers.entered_on(from_date: from_date, to_date: to_date))
        else
          @pagy, @stock_transfer_orders = pagy(StoreFrontModule::Orders::PurchaseOrder.stock_transfers.order(date: :desc))
        end
      end

      def show
        @order = StoreFrontModule::Orders::PurchaseOrder.find(params[:id])
        respond_to do |format|
          format.html
          if current_user.proprietor?
            format.xlsx
          end
        end
      end
      def edit
        @stock_transfer = StoreFrontModule::Orders::PurchaseOrder.find(params[:id])
      end
      def update
        @stock_transfer = StoreFrontModule::Orders::PurchaseOrder.find(params[:id])
        @stock_transfer.update(stock_transfer_params)
        if @stock_transfer.valid?
          @stock_transfer.save
          redirect_to store_front_module_stock_transfer_url(@stock_transfer), notice: "Updated successfully"
        else
          render :edit
        end
      end
      def destroy
        @order = StoreFrontModule::Orders::PurchaseOrder.find(params[:id])
        @order.destroy
        redirect_to store_front_module_stock_transfers_url, alert: "Deleted successfully"
      end
      private
      def stock_transfer_params
        params.require(:store_front_module_orders_purchase_order).
        permit(:destination_store_front_id)
      end
    end
  end
end
