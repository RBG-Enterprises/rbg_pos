# frozen_string_literal: true

ActiveAdmin.register StoreFronts::Stock, as: "Stocks" do
  actions :all, except: [:new, :destroy]
  includes :product

  index do
    selectable_column
    column :product do |stock|
      link_to(stock.product.name, admin_stock_path(stock))
    end
    column :barcode do |stock|
      link_to(stock.barcode, admin_stock_path(stock))
    end
    column :in_stock do |stock|
      stock.available_quantity
    end
  end

  filter :store_front
  filter :barcode
end
