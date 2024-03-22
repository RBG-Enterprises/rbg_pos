module StoreFrontModule
  class PurchaseOrderLineItemsController < AuthenticatedController
    def show
      @stock = StoreFrontModule::LineItems::PurchaseOrderLineItem.find(params[:id])
    end
  end
end
