class SaleD < ApplicationRecord
  belongs_to :caja
  belongs_to :cajero
  has_many :product_sales, inverse_of: :sale, dependent: :destroy
  accepts_nested_attributes_for :product_sales, allow_destroy: true

  before_create :generate_code

  def generate_code
  
    prefix = 'v'
    date_str = Date.today.strftime("%Y-%m-%d")
  
    # Contar cuántos productos ya se han creado hoy con esa categoría
    count_today = Sale.where("created_at >= ? AND created_at < ?", Date.today.beginning_of_day, Date.today.end_of_day)
                         .count
  
    # Sumar 1 para el siguiente número secuencial
    sequence = count_today + 1
    padded_seq = sequence.to_s.rjust(3, '0') # "001", "002", etc.
  
    self.code = "#{prefix}-#{date_str}-#{padded_seq}"
  end
end
