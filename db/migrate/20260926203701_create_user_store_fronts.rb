class CreateUserStoreFronts < ActiveRecord::Migration[6.1]
  def change
    create_table :user_store_fronts do |t|
      t.belongs_to :user, foreign_key: true, null: false
      t.belongs_to :store_front, foreign_key: true, null: false

      t.timestamps
    end

    add_index :user_store_fronts, [:user_id, :store_front_id], unique: true

    # Backfill: every user with a home store front keeps access to it.
    up_only do
      execute <<~SQL.squish
        INSERT INTO user_store_fronts (user_id, store_front_id, created_at, updated_at)
        SELECT id, store_front_id, NOW(), NOW() FROM users
        WHERE store_front_id IS NOT NULL
        ON CONFLICT (user_id, store_front_id) DO NOTHING
      SQL
    end
  end
end
