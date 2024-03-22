module StoreFrontModule
  module Settings
    class SellingPricesController < AuthenticatedController
      def new
        @product = Product.find(params[:product_id])
        @unit_of_measurement = StoreFrontModule::UnitOfMeasurement.find(params[:unit_of_measurement_id])
        @selling_price = StoreFrontModule::SellingPriceUpdate.new
      end
      def create
        @selling_price = StoreFrontModule::SellingPriceUpdate.new(price_params)
        if @selling_price.valid?
          @selling_price.update_price!
          redirect_to product_url(@selling_price.find_product), notice: "Price updated successfully."
        else
          render :new
        end
      end

      private
      def price_params
        params.require(:store_front_module_selling_price_update).permit(:selling_price, :product_id, :unit_of_measurement_id, :date, :store_front_ids => [])
      end
    end
  end
end
