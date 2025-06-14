class CreateUserSales < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sales do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :sale_date

      t.timestamps
    end
  end
end
