module StoreFrontModule
  module Registries
    class PurchaseOrderRegistry < Registry
      has_many :purchase_order_line_items, class_name: "StoreFrontModule::LineItems::PurchaseOrderLineItem", foreign_key: 'registry_id', dependent: :destroy


      def parse_for_records
        product_spreadsheet = Roo::Spreadsheet.open(spreadsheet.path)
        header = product_spreadsheet.row(1)
        (2..product_spreadsheet.last_row).each do |i|
          row = Hash[[header, product_spreadsheet.row(i)].transpose]
          Rails.logger.info(row)
          create_or_find_product(row)
          create_or_find_line_item(row)
          find_or_create_selling_price(row)
        end
      end

      def create_or_find_product(row)
        product = Product.find_by(name: row["Product Name"])
          if product.present?
          product
        else
          Product.create(name: row["Product Name"], category: find_category(row),  business:  employee.business)
        end
      end

      def create_or_find_line_item(row)
        stock = ::StoreFronts::Stock.create!(
          available:           true,
          store_front:         employee.store_front,
          product:             find_product(row),
          barcode:             bar_code(row),
          unit_of_measurement: unit_of_measurement(row)
        )
        StoreFrontModule::LineItems::PurchaseOrderLineItem.create!(
          store_front:         employee.store_front,
          stock:               stock,
          quantity:            quantity(row),
          unit_cost:           unit_cost(row),
          total_cost:          total_cost(row),
          product:             find_product(row),
          unit_of_measurement: unit_of_measurement(row),
          bar_code:            bar_code(row),
          registry_id:         self.id)
      end

      def quantity(row)
        row["Quantity"].to_f
      end
      def find_category(row)
        Category.find_or_create_by(name: row["Category"])
      end

      def unit_cost(row)
        row["Unit Cost"].to_f
      end

      def total_cost(row)
        row["Total Cost"].to_f
      end

      def bar_code(row)
        normalized_barcode(row)
      end

      def base_measurement(row)
        row["Base Measurement"] || true
      end

      def find_product(row)
        Product.find_or_create_by(name: row["Product Name"], business: employee.store_front.business)
      end

      def conversion_quantity(row)
        row["Conversion Quantity"] || 1
      end

      def unit_quantity(row)
        row["Quantity"] || 1
      end

      def unit_code(row)
        row["UOM"]
      end

      def lagawe_selling_price(row)
        row["Lagawe Selling Price"]
      end

      def lamut_selling_price(row)
        row["Lamut Selling Price"]
      end

      def alfonso_lista_selling_price(row)
        row["Alfonso Lista Selling Price"]
      end

      def maddela_selling_price(row)
        row["Maddela Selling Price"]
      end

      def quirino_selling_price(row)
        row["Quirino Consumer Goods Trading Selling Price"]
      end

      def unit_of_measurement(row)
        StoreFrontModule::UnitOfMeasurement.find_or_create_by!(
          unit_code:           unit_code(row),
          product:             find_product(row),
          base_measurement:    base_measurement(row),
          conversion_quantity: conversion_quantity(row),
          quantity:            1
          )
      end

      def find_or_create_selling_price(row)
        lagawe          = StoreFront.find_by(name: "Lagawe")
        alfonso_lista   = StoreFront.find_by(name: "Alfonso Lista")
        lamut           = StoreFront.find_by(name: "Lamut")
        maddela         = StoreFront.find_by(name: 'Maddela')
        quirino_trading = StoreFront.find_by(name: "Quirino Consumer Goods Trading")


        StoreFrontModule::SellingPrice.create!(
          price:               lagawe_selling_price(row),
          product:             find_product(row),
          store_front:         lagawe,
          unit_of_measurement: unit_of_measurement(row))

        StoreFrontModule::SellingPrice.create!(
          price:               alfonso_lista_selling_price(row),
          product:             find_product(row),
          store_front:         alfonso_lista,
          unit_of_measurement: unit_of_measurement(row))

        StoreFrontModule::SellingPrice.create!(
          price:               lamut_selling_price(row),
          product:             find_product(row),
          store_front:         lamut,
          unit_of_measurement: unit_of_measurement(row))

        StoreFrontModule::SellingPrice.create!(
          price:               maddela_selling_price(row),
          product:             find_product(row),
          store_front:         maddela,
          unit_of_measurement: unit_of_measurement(row))

        StoreFrontModule::SellingPrice.create!(
          price:               quirino_selling_price(row),
          product:             find_product(row),
          store_front:         quirino_trading,
          unit_of_measurement: unit_of_measurement(row))
      end

      def find_unit_of_measurement(row)
        find_product(row).unit_of_measurements.find_by(
          unit_code:           unit_code(row),
          base_measurement:    base_measurement(row),
          conversion_quantity: conversion_quantity(row),
          quantity:            unit_quantity(row))
      end

      def normalized_barcode(row)
        if row["Barcode"].to_s.include?(".")
          row["Barcode"].to_s.chop.gsub(".", "")
        else
          row["Barcode"].to_s
        end
      end
    end
  end
end
