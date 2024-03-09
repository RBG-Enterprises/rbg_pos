# frozen_string_literal: true

namespace :stocks do
  desc 'Update stock availability'

  task update_available_quantity: :environment do
    StoreFronts::Stock.all.find_each(batch_size: 100) do |stock|
      stock.update_available_quantity!
    end
  end

  task update_availability: :environment do
    StoreFronts::Stock.all.find_each(batch_size: 100) do |stock|
      stock.update_availability!
    end
  end
end
