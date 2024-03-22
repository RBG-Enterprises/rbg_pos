module Accounting
	class FundTransfersController < AuthenticatedController
		def new
			@entry = AccountingModule::FundTransferForm.new
		end
		def create
			@entry = AccountingModule::FundTransferForm.new(entry_params)
			if @entry.valid?
				@entry.save
				redirect_to accounting_index_url, notice: "Fund Transfer saved successfully."
			else
				render :new
			end
		end

		private
		def entry_params
			params.require(:accounting_module_fund_transfer_form).permit(:cashier_id, :entry_date, :reference_number, :description, :debit_account_id, :credit_account_id, :amount)
		end
	end
end
