class CreateCajeros < ActiveRecord::Migration[7.1]
  def change
    create_table :cajeros do |t|
      t.string :nombre
      t.references :caja, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
