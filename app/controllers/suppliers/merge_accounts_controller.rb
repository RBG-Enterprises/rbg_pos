module Suppliers
  class MergeAccountsController < AuthenticatedController
    def new
      @merge_account = Suppliers::AccountMergingForm.new
    end
    def create
      @merge_account = Suppliers::AccountMergingForm.new(merge_params)
      if @merge_account.valid?
        @merge_account.save
        redirect_to settings_url, notice: "Supplier accounts merged successfully."
      else
        render :new
      end
    end

    private
    def merge_params
      params.require(:suppliers_account_merging_form).permit(:old_supplier_id, :new_supplier_id)
    end
  end
end
