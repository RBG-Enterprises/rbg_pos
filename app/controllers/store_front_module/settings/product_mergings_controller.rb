module StoreFrontModule
  module Settings
    class ProductMergingsController < AuthenticatedController
      def new
        @product_merging = StoreFrontModule::Settings::ProductMerging.new
      end
      def create
        @product_merging = StoreFrontModule::Settings::ProductMerging.new(merging_params)
        if @product_merging.valid?
          @product_merging.merge_products!
          redirect_to settings_url, notice: "Products merged successfully."
        else
          render :new
        end
      end

      private
      def merging_params
        params.require(:store_front_module_settings_product_merging).permit(:old_product_id, :new_product_id)
      end
    end
  end
end
