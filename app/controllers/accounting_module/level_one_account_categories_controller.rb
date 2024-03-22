module AccountingModule
  class LevelOneAccountCategoriesController < AuthenticatedController
    def index
      @level_one_account_categories = current_store_front.level_one_account_categories
    end

    def new
      @level_one_account_category = current_store_front.level_one_account_categories.build
    end

    def create
      @level_one_account_category = current_store_front.level_one_account_categories.create(l1_account_category_params)
      if @level_one_account_category.valid?
        @level_one_account_category.save!

        redirect_to accounting_module_level_one_account_category_url(@level_one_account_category), notice: 'Level One Account Category saved successfully.'
      else
        render :new
      end
    end
    def show
      @level_one_account_category = current_store_front.level_one_account_categories.find(params[:id])
    end


    private

    def l1_account_category_params
      params.require(:accounting_module_account_categories_level_one_account_category).
      permit(:title, :code, :contra, :type)
    end
  end
end
