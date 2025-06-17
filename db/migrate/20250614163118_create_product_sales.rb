class CreateProductSales < ActiveRecord::Migration[7.1]
  def change
    create_table :product_sales do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.float :unit_price
      t.float :discount

      t.timestamps
    end
  end
end
