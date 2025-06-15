class CreatePruebas < ActiveRecord::Migration[7.1]
  def change
    create_table :pruebas do |t|
      t.string :nombre
      t.string :description

      t.timestamps
    end
  end
end
