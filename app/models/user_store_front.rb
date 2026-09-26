class UserStoreFront < ApplicationRecord
  belongs_to :user
  belongs_to :store_front

  validates :store_front_id, uniqueness: { scope: :user_id }
end
