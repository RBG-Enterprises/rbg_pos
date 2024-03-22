module StoreFrontModule
  module Registries
    class PurchaseOrderLineItemsController < AuthenticatedController
      def destroy
        @registry = StoreFrontModule::Registries::PurchaseOrderRegistry.find(params[:purchase_order_registry_id])
        @line_item = @registry.purchase_order_line_items.find(params[:id])
        @line_item.destroy
        redirect_to store_front_module_purchase_order_registry_url(@registry), notice: "Removed successfully."
      end
    end
  end
end
