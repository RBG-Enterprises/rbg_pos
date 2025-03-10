# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby "3.3.0"

gem "active_interaction", "~> 5.3"
gem "prawn-icon"
gem "rails", "6.1.7.7"
gem "audited", "~> 4.7"
gem "autonumeric-rails"
gem "spreadsheet"
gem "rqrcode"
gem "webpacker"
gem "sidekiq"
# gem 'activerecord-postgis-adapter'
gem "pg_search"
gem "chronic"
gem "paperclip"
gem "pg", ">= 0.18", "< 2.0"
gem "puma"
gem "rubyzip", ">= 1.2.1"
gem "axlsx", git: "https://github.com/randym/axlsx.git", ref: "c8ac844"
gem "caxlsx_rails"
gem "mina", require: false
gem "mina-puma", require: false, github: "untitledkingdom/mina-puma"
gem "uglifier", ">= 1.3.0"
gem "coffee-rails"
gem "groupdate"
gem "turbolinks", "~> 5"
gem "public_activity"
gem "redis", "~> 4.0"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "barby"
gem "simple_form"
gem "devise"
gem "devise_invitable"
gem "mini_magick"
gem "bootsnap", require: false
gem "prawn"
gem "prawn-table"
gem "chartkick"
gem "precise_distance_of_time_in_words"
gem "pundit"
gem "will_paginate", "~> 3.3"
gem "money-rails", "~>1.12"
gem "roo", "2.7.0"
gem "simple_calendar"
gem "pdf-reader"
gem "pagy"
gem "ffi", "1.15.3"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "net-smtp", require: false
gem "net-imap", require: false
gem "net-pop", require: false
gem "listen", ">= 3.0.5", "< 3.2"
gem "bullet"

group :development do
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails", group: :production
  gem "faker", group: :production
  gem "pry-rails"
end

group :test do
  gem "shoulda-matchers"
  gem "capybara"
  gem "webdrivers"
  gem "database_rewinder"
end

gem "rack-mini-profiler", require: false

gem "matrix", "~> 0.4.2"

gem "dartsass-rails", "~> 0.5.0"
gem "rubocop", require: false
gem "rubocop-rails", require: false
gem "rubocop-rspec", require: false
gem "rubocop-shopify", require: false
