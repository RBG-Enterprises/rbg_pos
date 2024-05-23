module AccountingModule
  class Entry < ApplicationRecord
    include PgSearch::Model
    multisearchable against: [:description, :reference_number]
    enum entry_type: [:cash_order, :credit_order, :cash_stock, :credit_stock, :customer_credit_payment, :expense, :supplier_credit_payment,
      :work_order_credit, :work_order_payment, :work_order_service_charge, :stock_transfer, :fund_transfer, :other_sale, :owner_withdraw]
    belongs_to :commercial_document, :polymorphic => true, optional: true
    belongs_to :user,          optional: true
    belongs_to :recorder,      class_name: "User", optional: true
    has_many :amounts,         class_name: "AccountingModule::Amount", dependent: :destroy
    has_many :credit_amounts,  :class_name => 'AccountingModule::CreditAmount', :inverse_of => :entry, dependent: :destroy
    has_many :debit_amounts,   :class_name => 'AccountingModule::DebitAmount', :inverse_of => :entry, dependent: :destroy
    has_many :credit_accounts, :through => :credit_amounts, :source => :account, :class_name => 'AccountingModule::Account'
    has_many :debit_accounts,  :through => :debit_amounts, :source => :account, :class_name => 'AccountingModule::Account'
    has_many :vouchers, dependent: :destroy

    validates :description, presence: true
    validate :has_credit_amounts?
    validate :has_debit_amounts?
    validate :amounts_cancel?

    accepts_nested_attributes_for :credit_amounts, :debit_amounts, allow_destroy: true

    before_save :set_default_date

    delegate :first_and_last_name, :name, to: :recorder, prefix: true, allow_nil: true
    delegate :name, to: :commercial_document, prefix: true, allow_nil: true
    def self.entered_on(options={})
      if options[:from_date] && options[:to_date]
        date_range = DateRange.new(from_date: options[:from_date], to_date: options[:to_date])
        where('entry_date' => (date_range.start_date..date_range.end_date))
      else
        all
      end
    end
    def self.total(hash={})
      if hash[:from_date] && hash[:to_date]
        from_date = hash[:from_date].kind_of?(DateTime) ? hash[:from_date] : DateTime.parse(hash[:from_date])
        to_date = hash[:to_date].kind_of?(DateTime) ? hash[:to_date] : DateTime.parse(hash[:to_date])
        where('entry_date' => from_date..to_date).distinct.map{|a| a.credit_amounts.sum(:amount)}.sum
      else
        all.distinct.map{|a| a.credit_amounts.sum(:amount)}.sum
      end
    end
    def total
      debit_amounts.sum(:amount)
    end

    private
      def set_default_date
        todays_date = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
        self.entry_date ||= todays_date
      end

      def has_credit_amounts?
        errors[:base] << "Entry must have at least one credit amount" if self.credit_amounts.blank?
      end

      def has_debit_amounts?
        errors[:base] << "Entry must have at least one debit amount" if self.debit_amounts.blank?
      end

      def amounts_cancel?
        errors[:base] << "The credit and debit amounts are not equal" if credit_amounts.balance_for_new_record != debit_amounts.balance_for_new_record
      end
  end
end
