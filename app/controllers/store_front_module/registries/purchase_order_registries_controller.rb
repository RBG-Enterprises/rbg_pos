module StoreFrontModule
  module Registries
    class PurchaseOrderRegistriesController < AuthenticatedController
      def new
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.new
      end
      def create
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.create(registry_params)
        if @registry.valid?
          @registry.save
          @registry.parse_for_records
          redirect_to store_front_module_purchase_order_registry_url(@registry), notice: "Uploaded successfully"
        else
          render :new
        end
      end

      def show
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.find(params[:id])
        @purchase_order_line_items = @registry.purchase_order_line_items.order(created_at: :asc).paginate(page: params[:page], per_page: 35)
        @cart = current_cart
        @purchase_order = StoreFrontModule::Orders::PurchaseOrderProcessing.new
      end
      def destroy
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.find(params[:id])
        @registry.destroy
        redirect_to store_front_module_purchase_orders_url, notice: "Purchases cancelled successfully."
      end

      private
      def registry_params
        params.require(:store_front_module_registries_purchase_order_registry).permit(:spreadsheet, :employee_id)
      end
    end
  end
end
