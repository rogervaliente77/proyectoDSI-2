class CreateSales < ActiveRecord::Migration[7.1]
  def change
    create_table :sales do |t|
      t.datetime :sold_at
      t.string :client_name
      t.string :status
      t.references :caja, null: false, foreign_key: true
      t.references :cajero, null: false, foreign_key: true
      t.integer :client_id
      t.float :total_amount

      t.timestamps
    end
  end
end
