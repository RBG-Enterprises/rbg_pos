module StoreFrontModule
  class SellingPrice < ApplicationRecord
    belongs_to :store_front
    belongs_to :product
    belongs_to :unit_of_measurement, class_name: "StoreFrontModule::UnitOfMeasurement"

    validates :price, numericality: true, presence: true
    before_save :set_default_date

    def self.price_for_unit_of_measurement(unit_of_measurement:)
      for_unit_of_measurement(unit_of_measurement: unit_of_measurement).price
    end

    def self.for_unit_of_measurement(unit_of_measurement:)
      where(unit_of_measurement: unit_of_measurement).current
    end

    def self.price_for_store_front(store_front:)
      for_store_front(store_front: store_front).try(:price)
    end

    def self.for_store_front(store_front:)
      where(store_front: store_front).current
    end

    def self.current
      order(created_at: :desc).first
    end

    def self.current_price
      current.try(:price)
    end

    private
    def set_default_date
      self.date ||= Time.zone.now
    end
  end
end
