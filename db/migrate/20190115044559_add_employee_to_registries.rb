class AddEmployeeToRegistries < ActiveRecord::Migration[5.1]
  def change
    add_reference :registries, :employee, foreign_key: { to_table: :users }
  end
end
