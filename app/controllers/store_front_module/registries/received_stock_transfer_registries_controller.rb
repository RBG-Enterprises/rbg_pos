 module StoreFrontModule
  module Registries
    class ReceivedStockTransferRegistriesController < AuthenticatedController
      def new
        @registry = StoreFrontModule::Registries::ReceivedStockTransferRegistry.new
      end
      def create
        @registry = StoreFrontModule::Registries::ReceivedStockTransferRegistry.new(registry_params)
        if @registry.save
          @registry.parse_for_records
          redirect_to store_front_module_received_stock_transfer_registry_url(@registry), notice: "uploaded successfully"
        else
          render :new
        end
      end
      def show
        @registry = StoreFrontModule::Registries::ReceivedStockTransferRegistry.find(params[:id])
        @cart = current_cart
        @received_stock_transfer_order = StoreFrontModule::Orders::ReceivedStockTransferOrderProcessing.new
      end
      private
      def registry_params
        params.require(:store_front_module_registries_received_stock_transfer_registry).
        permit(:spreadsheet)
      end
    end
  end
end
