class Product < ApplicationRecord
	include PgSearch::Model
  has_one_attached :avatar
  multisearchable against: [:name]
	pg_search_scope :text_search, against: [:name]
  pg_search_scope :text_search_with_barcode, against: [:name],
  :associated_against => {
    :purchases => [:bar_code]}

  belongs_to :business
  belongs_to :category,           optional: true
	has_many :line_items
	has_many :orders,               through: :line_items
	has_many :sales_returns,        class_name: "StoreFrontModule::LineItems::SalesReturnOrderLineItem"
	has_many :unit_of_measurements, class_name: "StoreFrontModule::UnitOfMeasurement"
  has_many :purchases,            class_name: 'StoreFrontModule::LineItems::PurchaseOrderLineItem'
  has_many :internal_uses,        class_name: 'StoreFrontModule::LineItems::InternalUseOrderLineItem'
  has_many :sales,                class_name: 'StoreFrontModule::LineItems::SalesOrderLineItem'
  has_many :sales_orders,         through: :sales, :source => :sales_order, :class_name => 'StoreFrontModule::Orders::SalesOrder'
  has_many :purchase_orders,      through: :purchases, :source => :order, :class_name => 'StoreFrontModule::Orders::PurchaseOrder'
  has_many :sales_returns,        class_name: "StoreFrontModule::LineItems::SalesReturnOrderLineItem"
  has_many :purchase_returns,     class_name: "StoreFrontModule::LineItems::PurchaseReturnOrderLineItem"
  has_many :spoilages,            class_name: "StoreFrontModule::LineItems::SpoilageOrderLineItem"
  has_many :selling_prices,       class_name: "StoreFrontModule::SellingPrice"
  has_many :purchase_prices,      class_name: 'StoreFrontModule::PurchasePrice'
  has_many :stocks,               class_name: 'StoreFronts::Stock'
  has_many :available_stocks, -> { in_stocks }, class_name: 'StoreFronts::Stock'

  has_many :stock_transfers, through: :stocks
  has_many :stock_transfer_orders, through: :stock_transfers, source: :purchase_order

  validates :name, presence: true, uniqueness: { scope: :business_id }

  delegate :name, to: :category, prefix: true, allow_nil: true
  delegate :unit_code, to: :base_measurement, prefix: true, allow_nil: true
  before_save :set_default_image
  def base_measurement
    unit_of_measurements.base_measurement
  end

  def self.low_on_stock
    all.select{ |a| a.low_on_stock? }
  end
  def self.out_of_stock
    all.select{ |a| a.out_of_stock? }
  end
  def self.most_bought
    all.to_a.sort_by(&:line_items_count).reverse
  end
  def line_items_count
    line_items.total
  end

  def low_on_stock?
    !out_of_stock? && low_stock_count > in_stock
  end

  def out_of_stock?
    in_stock <= 0
  end

  def badge_color
    if out_of_stock?
      "danger"
    elsif low_on_stock?
      "warning"
    else
      "success"
    end
  end

  def last_purchase_cost
    latest_purchase.try(:unit_cost)
  end

  def latest_purchase
    purchases.last
  end

  def latest_purchase_order
    purchase_orders.latest
  end


  def self.import(file)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      prod = find_by(id: row["id"]) || new
      member.attributes = row.to_hash
      member.save!
    end
  end



	def in_stock(store_front:)
		stocks.
    where(store_front: store_front).
    processed.
    available_quantity
  end

	def sold_items_count
		sales_balance
	end
	def delivered_items_count
		purchases_balance
	end
	def transferred_stocks_count
    stock_transfers_balance
	end
	def returned_items_count
		sales_returns_balance
	end


  ################################
  def last_purchase_cost
    purchases.order(created_at: :desc).last.try(:unit_cost)
  end
  def available_quantity(args={})
    balance(args)
  end

  def balance(args={})
    store_front = args[:store_front]
    if store_front.present?
      stocks.processed.where(store_front: store_front).map{ |a| a.balance }.sum
    else
      stocks.processed.map{|a| a.balance }.sum
    end
  end

  def sales_balance(args={})
      sales.balance(args)
  end

  def sales_returns_balance(args={})
    sales_returns.balance(args)
  end

  def purchases_balance(args={})
    purchases.not_stock_transfers.balance(args)
  end
  def purchase_returns_balance(args={})
    purchase_returns.balance(args)
  end
  def spoilages_balance(args={})
    spoilages.balance(args)
  end

  def internal_use_orders_balance(args={})
    internal_uses.balance(args)
  end

  def delivered_stock_transfers_balance(args={})
    if args[:store_front].present?
      purchases.delivered_stock_transfers(store_front: args[:store_front]).
      balance(origin_store_front: args[:store_front])
    else
      0
    end
  end

  def set_default_image
    if !avatar.attached?
      self.avatar.attach(io: File.open(Rails.root.join('app', 'assets', 'images', 'default.png')), filename: 'default-image.png', content_type: 'image/png')
    end
  end
end
