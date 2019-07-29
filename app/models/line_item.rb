class LineItem < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :text_search, against: [:bar_code]
  multisearchable against: [:bar_code]
  belongs_to :store_front, optional: true
  belongs_to :stock,    class_name: 'StoreFronts::Stock', optional: true
  belongs_to :commercial_document, polymorphic: true, optional: true
  belongs_to :cart,     optional: true
  belongs_to :order,    optional: true
  belongs_to :product,  optional: true
  belongs_to :registry, optional: true
  belongs_to :referenced_line_item, class_name: "LineItem", optional: true
  belongs_to :unit_of_measurement, class_name: "StoreFrontModule::UnitOfMeasurement"

  delegate :unit_code, :conversion_multiplier, to: :unit_of_measurement, allow_nil: true
  delegate :name, to: :product, allow_nil: true
  delegate :name, to: :product, prefix: true, allow_nil: true
  delegate :name, to: :stock, prefix: true
  delegate :barcode, to: :stock, prefix: true, allow_nil: true



  def self.stock_transfers
    includes(:purchase_order).
    where('orders.supplier_type' => "StoreFront")
  end

  def self.entered_on(args={})
    from_date  = args.fetch(:from_date)
    to_date    = args.fetch(:to_date) || Date.current - 999.years
    date_range = DateRange.new(from_date: from_date, to_date: to_date)
    joins(:order).
    where('orders.date' => date_range.range)
  end

  def self.for_store_front(store_front)
    includes(:order).
    where('orders.store_front_id' => store_front.id)
  end

  def self.with_orders
    where.not(order_id: nil)
  end

  def self.processed
    with_orders
  end

  def self.total_cost
    all.sum(&:unit_cost_and_quantity)
  end

  def self.total
    total_converted_quantity
  end

  def self.total_converted_quantity
    processed.all.sum(&:converted_quantity)
  end

  def self.balance(args={})
    balance_finder(args.merge(line_items: self)).new(args.merge(line_items: self)).compute
  end


  def self.balance_finder(args={})
    klass = args.select{ |key, value| !value.nil?}.keys.sort.map{ |key| key.to_s.titleize }.join.gsub(" ", "")
    ("StoreFrontModule::BalanceFinders::" + klass).constantize
  end

  def unit_cost_and_quantity
  	unit_cost * quantity
  end

  def converted_quantity
    quantity * default_conversion_multiplier
  end


  def processed?
    order.present?
  end


  private
  def default_conversion_multiplier
    conversion_multiplier || 1
  end
end
