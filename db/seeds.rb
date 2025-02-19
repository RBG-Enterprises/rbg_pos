# frozen_string_literal: true

Dir[Rails.root.join("db/seeds/*.rb").to_s].sort.each { |seed| load seed }
