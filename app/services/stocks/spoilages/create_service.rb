# frozen_string_literal: true

module Stocks
  module Spoilages
    class CreateService < ActiveInteraction::Base
      object :stock, class: 'StoreFronts::Stock'
      object :store_front
      object :user

      integer :quantity

      string :reference_number, :description, default: nil

      validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }
      def execute
        create_spoilage_order
      end

      private def create_spoilage_order
        spoilage_order = StoreFrontModule::Orders::SpoilageOrder.create!(
          date: Date.current,
          description: description,
          employee_id: user.id,
          reference_number: reference_number,
          store_front: store_front,
          account_number: SecureRandom.uuid
        )

        spoilage_order.spoilage_order_line_items.create!(quantity: quantity, stock: stock, unit_of_measurement: stock.unit_of_measurement)
      end
    end
  end
end