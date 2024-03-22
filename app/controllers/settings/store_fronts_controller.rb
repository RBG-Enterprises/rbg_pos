module Settings
  class StoreFrontsController < AuthenticatedController
    def new
      @store_front = StoreFront.new
    end
    def create
      @store_front = StoreFront.create(store_front_params)
      if @store_front.save
        @store_front.save
        redirect_to settings_url, notice: 'Store Front created successfully.'
      else
        render :new
      end
    end

    def edit
      @store_front = StoreFront.find(params[:id])
    end

    def update
      @store_front = StoreFront.find(params[:id])
      @store_front.update(store_front_params)
      if @store_front.valid?
        @store_front.save
        redirect_to settings_url, notice: "Store Front updated successfully."
      else
        render :edit
      end
    end

    private
    def store_front_params
      params.require(:store_front).permit(
        :name,
        :address,
        :business_id,
        :merchandise_inventory_account_id,
        :sales_account_id,
        :sales_return_account_id,
        :sales_discount_account_id,
        :sales_return_account_id,
        :cost_of_goods_sold_account_id,
        :receivable_account_id,
        :internal_use_account_id,
        :purchase_return_account_id,
        :spoilage_account_id,
        :service_revenue_account_id
        )
    end
  end
end
