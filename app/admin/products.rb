# frozen_string_literal: true

ActiveAdmin.register Product do
  permit_params :name
  includes :category
  index do
    selectable_column
    id_column
    column :name do |product|
      link_to(product.name, admin_product_path(product))
    end
    column :description
    column :retail_price
    column :wholesale_price
    column :category_name
  end

  filter :name
  filter :description
  filter :category

  show do
    active_admin_comments
  end
end
