class CreateCajas < ActiveRecord::Migration[7.1]
  def change
    create_table :cajas do |t|
      t.string :nombre

      t.timestamps
    end
  end
end
