class AddDeactivatedAtToStoreFronts < ActiveRecord::Migration[6.1]
  def change
    add_column :store_fronts, :deactivated_at, :datetime
  end
end
