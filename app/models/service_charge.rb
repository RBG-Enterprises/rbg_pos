class ServiceCharge < ApplicationRecord
  enum :charge_type, [:regular, :additional]

  validates :description, :amount, presence: true
  validates :amount, numericality: { greater_than: 0.01 }
end
