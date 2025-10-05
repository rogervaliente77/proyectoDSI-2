# app/models/sale.rb
class Sale
  include Mongoid::Document
  include Mongoid::Timestamps # Para created_at y updated_at

  field :sold_at, type: DateTime
  field :client_name, type: String
  field :status, type: String
  field :client_id, type: Integer
  field :total_amount, type: Float
  field :code, type: String

  # Relaciones
  belongs_to :caja, class_name: "Caja", inverse_of: :sales
  belongs_to :cajero, class_name: "Cajero", inverse_of: :sales
  has_many :product_sales, class_name: "ProductSale", inverse_of: :sale, dependent: :destroy

  accepts_nested_attributes_for :product_sales, allow_destroy: true

  # Callbacks
  before_create :generate_code

  def generate_code
    prefix = 'v'
    date_str = Date.today.strftime("%Y-%m-%d")

    count_today = Sale.where(
      :created_at.gte => Date.today.beginning_of_day,
      :created_at.lt  => Date.today.end_of_day
    ).count

    sequence = count_today + 1
    padded_seq = sequence.to_s.rjust(3, '0')

    self.code = "#{prefix}-#{date_str}-#{padded_seq}"
  end

  # Retorna todos los product_sales que no tienen devolución
  def products_available_for_return
    product_sales.select do |ps|
      Devolucion.where(sale_id: self.id, sale_devolucion_detalle: ps.id).empty?
    end
  end


   # Retorna true si hay productos disponibles para devolver
  def has_products_available_for_return?
    products_available_for_return.any?
  end
end

