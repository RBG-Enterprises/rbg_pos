module Accounting
	class RemittancesController < AuthenticatedController
		def new
			@remittance = AccountingModule::RemittanceForm.new
		end
		def create
			@remittance = AccountingModule::RemittanceForm.new(entry_params)
			if @remittance.valid?
				@remittance.save
				redirect_to accounting_index_url, notice: "Collection remittance saved successfully."
			else
				render :new
			end
		end

		private
		def entry_params
			params.require(:accounting_module_remittance_form).permit(:recorder_id, :cashier_id, :entry_date, :reference_number, :description, :amount)
		end
	end
end
