module AccountingModule
	class RemittanceForm
		include ActiveModel::Model
		attr_accessor :entry_date,
	                :cashier_id,
	                :proprietor_id,
		              :reference_number,
		              :description,
		              :amount,
		              :debit_account_id,
		              :credit_account_id,
                  :recorder_id
		validates :entry_date, :description, :cashier_id, presence: true
		validates :amount, presence: true, numericality: true
	  def save
	  	ActiveRecord::Base.transaction do
	  		@created_entry = create_entry
	  	end
	  end

	  def created_entry
	  	@created_entry
	  end

	  private
	  def create_entry
	  	AccountingModule::Entry.create!(recorder_id: recorder_id, commercial_document_id: cashier_id, commercial_document_type: "User", entry_date: entry_date, reference_number: reference_number, description: description,
	  		credit_amounts_attributes: [amount: amount, account: credit_account],
	  		debit_amounts_attributes: [amount: amount, account: debit_account])
	  end
	  def find_proprietor
	  	User.find_by_id(recorder_id)
	  end
	  def find_cashier
	  	User.find_by_id(cashier_id)
	  end
	  def credit_account
      AccountingModule::Account.find(credit_account_id)
	  end

	  def debit_account
	  	AccountingModule::Account.find(debit_account_id)
	  end
	end
end
