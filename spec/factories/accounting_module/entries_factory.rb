FactoryBot.define do
  factory :entry, class: AccountingModule::Entry do
    description { 'entry description' }
    
    factory :entry_with_credit_and_debit, :class => AccountingModule::Entry do |entry_cd|
      entry_cd.after(:build) do |t|
        t.credit_amounts << FactoryBot.build(:credit_amount, :entry => t)
        t.debit_amounts << FactoryBot.build(:debit_amount, :entry => t)
      end
    end
  end
end
