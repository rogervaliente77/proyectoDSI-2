class AddCajaNumberToCajas < ActiveRecord::Migration[7.1]
  def change
    add_column :cajas, :caja_number, :integer
  end
end
