module Products
  class SettingsController < AuthenticatedController
    def index
      @product = current_business.products.find(params[:product_id])
    end
  end
end
