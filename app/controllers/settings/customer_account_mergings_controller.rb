module Settings
  class CustomerAccountMergingsController < AuthenticatedController
    def new
      @merging = Customers::AccountMerging.new
    end
    def create
      @merging = Customers::AccountMerging.new(merging_params)
      if @merging.valid?
        @merging.merge!
        redirect_to settings_url, notice: "Accounts merged successfully."
      else
        render :new
      end
    end


    private
    def merging_params
      params.require(:customers_account_merging).permit(:old_customer_id, :new_customer_id)
    end
  end
end
