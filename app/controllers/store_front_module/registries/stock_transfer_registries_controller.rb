module StoreFrontModule
  module Registries
    class StockTransferRegistriesController < AuthenticatedController
      def new
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.new
      end
      def create
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.new(registry_params)
        if @registry.valid?
          @registry.save
          @registry.parse_for_records
          redirect_to store_front_module_stock_transfer_registry_url(@registry), notice: "uploaded successfully"
        else
          render :new
        end
      end
      def show
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.find(params[:id])
        @cart = current_cart
        @stock_transfer_order = StoreFrontModule::Orders::StockTransferOrderProcessing.new
      end
      private
      def registry_params
        params.require(:store_front_module_registries_purchase_order_registry).
        permit(:spreadsheet, :employee_id)
      end
    end
  end
end
