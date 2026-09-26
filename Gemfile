# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby "3.3.0"

gem "active_interaction", "~> 5.3"
# Rails 6.1 is incompatible with concurrent-ruby >= 1.3.5 (LoggerThreadSafeLevel).
# Drop this pin after upgrading to Rails 7.1+.
gem "concurrent-ruby", "1.3.4"
gem "prawn-icon"
gem "rails", "~> 7.0.0"
gem "audited", "~> 5.0"
gem "autonumeric-rails"
gem "spreadsheet"
gem "rqrcode"
gem "webpacker"
gem "sidekiq"
# gem 'activerecord-postgis-adapter'
gem "pg_search"
gem "chronic"
gem "pg", ">= 0.18", "< 2.0"
gem "puma"
gem "rubyzip", ">= 1.2.1"
gem "caxlsx_rails"
gem "sprockets-rails"
gem "mina", require: false
gem "mina-puma", require: false, github: "untitledkingdom/mina-puma"
gem "terser"
gem "groupdate"
gem "turbolinks", "~> 5"
gem "redis", "~> 5.0"
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
gem "pundit"
gem "will_paginate", "~> 3.3"
gem "money-rails", "~>1.12"
gem "roo", "~> 2.10"
gem "simple_calendar"
gem "pdf-reader"
gem "pagy"
gem "ffi", ">= 1.15"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "net-smtp", require: false
gem "net-imap", require: false
gem "net-pop", require: false
gem "csv", require: false
gem "listen", "~> 3.8"
gem "bullet"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
end

group :test do
  gem "shoulda-matchers"
  gem "capybara"
  gem "selenium-webdriver"
end

gem "rack-mini-profiler", require: false

gem "matrix", "~> 0.4.2"

gem "dartsass-rails", "~> 0.5.0"
gem "rubocop", require: false
gem "rubocop-rails", require: false
gem "rubocop-rspec", require: false
gem "rubocop-shopify", require: false
