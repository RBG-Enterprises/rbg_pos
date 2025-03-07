class Order < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :text_search, against: [:reference_number, :search_term]
  pg_search_scope :text_search_with_stocks, against: [:reference_number, :search_term],
  associated_against: { line_items: [:bar_code] },
  associated_against: { stocks: [:barcode] },
  associated_against: { products: [:name] }

  multisearchable against: [:reference_number, :description]

  belongs_to :store_front
  belongs_to :commercial_document,     polymorphic: true, optional: true
  belongs_to :employee,                class_name: "User", foreign_key: 'employee_id'
  has_one :cash_payment,               as: :cash_paymentable, class_name: "StoreFrontModule::CashPayment"
  has_one :entry,                      as: :commercial_document, class_name: "AccountingModule::Entry", dependent: :destroy
  belongs_to :voucher,                 optional: true
  has_many :line_items,                dependent: :destroy
  has_many :stocks,                    through: :line_items
  has_many :products, through: :stocks
  delegate :full_name, to: :technician, prefix: true, allow_nil: true #WTF
  delegate :cash_tendered, :discount_amount, to: :cash_payment, prefix: true, allow_nil: true
  delegate :full_name, to: :employee, prefix: true, allow_nil: true
  delegate :name, to: :store_front, prefix: true

  before_validation :set_date

  validates :account_number,  presence: true, uniqueness: true
  validates :store_front_id, presence: true

  def self.total_cost_less_discount
    all.map{|a| a.total_cost_less_discount }.to_a.sum
  end



  def self.credit
    where(credit: true)
  end
  def self.for_store_front(store_front)
    where(store_front: store_front)
  end
  def self.total
    total_cost
  end

  def self.total_cost
    all.map{|a| a.total_cost }.compact.sum
  end

  def self.total_discount
    all.map{|a| a.discount_amount }.compact.sum
  end

  def self.total_cost_of_goods_sold
    all.map{|a| a.cost_of_goods_sold }.compact.sum
  end

  def self.total_income
    all.map{|a| a.income }.compact.sum
  end

  def self.ordered_on(args={})
    if args[:from_date] && args[:to_date]
      date_range = DateRange.new(from_date: args[:from_date], to_date: args[:to_date])

      where('date' => date_range.start_date..date_range.end_date)
    else
      all
    end
  end

  def total_cost
    if line_items.present?
      line_items.sum(&:total_cost)
    else
      cash_payment.try(:cash_tendered) || 0
    end
  end

  def total_quantity
    line_items.sum(&:quantity)
  end

  def self.created_between(hash={})
    ordered_on(args)
  end
  def line_items_total_cost
    line_items.sum(:total_cost)
  end


  def line_items_name
    line_items.map { |a| ["#{a.product_name} (#{a.try(:bar_code)})"] }.to_s.gsub("[", "").gsub("]", "").gsub('"', "")
  end

  def line_items_name_and_barcode
    line_items.map{|a| a.stock_name_and_barcode }.to_s.gsub("[", "").gsub("]", "").gsub('"', "")
  end

  def cost_of_goods_sold
    line_items.sum(&:cost_of_goods_sold)
  end


  def income
    total_cost_less_discount - cost_of_goods_sold
  end

  def total_cost_less_discount
    total_cost - discount_amount
  end

  def discount_amount
    cash_payment.try(:discount_amount) || 0
  end

  private
  def set_date
  	self.date ||= Time.zone.now
  end
end
