class AddIndexToStockBarcodes < ActiveRecord::Migration[6.1]
  def change
    add_index :stocks, :barcode, if_not_exists: true
  end
end
