module StoreFrontModule
  class PurchaseOrderLineItemRegistriesController < AuthenticatedController
    def create
      @registry = Uploads::PurchaseOrderLineItem.new(registry_params)
      if @registry.valid?
        @registry.process!
        redirect_to new_store_front_module_purchase_order_line_item_processing_url
      else
        redirect_to new_store_front_module_purchase_order_line_item_processing_url, alert: 'Invalid file.'
      end
    end
    def show
      @registry = Registry.find(params[:id])
      @stocks = @registry.stocks.all.paginate(page: params[:page], per_page: 35)
    end
    def destroy
      @registry = Registry.find(params[:id])
      @registry.destroy
      redirect_to products_url, notice: "Deleted successfully."
    end

    private
     def registry_params
      params.require(:uploads_purchase_order_line_item).permit(:spreadsheet, :cart_id)
    end
  end
end
