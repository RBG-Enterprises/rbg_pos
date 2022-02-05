class CreateRegistries < ActiveRecord::Migration[5.1]
  def change
    create_table :registries do |t|

      t.timestamps
    end
  end
end
