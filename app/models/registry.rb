# frozen_string_literal: true

require "roo"
class Registry < ApplicationRecord
  belongs_to :employee, class_name: "User"
  has_one_attached :spreadsheet

  has_many :line_items, dependent: :destroy
end
