module StoreFrontModule
  module StoreFronts
    class AccountsController < AuthenticatedController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @accounts = @store_front.accounts
      end

      def new
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @account     = @store_front.store_front_accounts.build
      end
      def create
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @account     = @store_front.store_front_accounts.create(store_front_account_params)
        if @account.valid?
          @account.save!
          redirect_to store_front_module_store_front_accounts_url(@store_front), notice: 'Account added successfully'
        else
          render :new
        end
      end

      private
      def store_front_account_params
        params.require(:store_fronts_store_front_account).
        permit(:account_id)
      end
    end
  end
end
