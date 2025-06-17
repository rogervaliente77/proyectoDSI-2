class Product < ApplicationRecord
  
  has_many :product_sales
  belongs_to :category

  validates :name, :price, :quantity, presence: true

  before_create :generate_code

  def generate_code
    return unless self.category.present?
  
    prefix = category.name[0,3].upcase
    date_str = Date.today.strftime("%Y%m%d")
  
    # Contar cuántos productos ya se han creado hoy con esa categoría
    count_today = Product.where("created_at >= ? AND created_at < ?", Date.today.beginning_of_day, Date.today.end_of_day)
                         .where(category_id: category_id)
                         .count
  
    # Sumar 1 para el siguiente número secuencial
    sequence = count_today + 1
    padded_seq = sequence.to_s.rjust(3, '0') # "001", "002", etc.
  
    self.code = "#{prefix}-#{date_str}-#{padded_seq}"
  end
  
end