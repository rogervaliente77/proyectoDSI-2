# app/models/sale.rb
class Sale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sold_at, type: DateTime
  field :client_name, type: String
  field :status, type: String
  field :client_id, type: BSON::ObjectId
  field :total_amount, type: Float
  field :code, type: String
  field :user_id, type: BSON::ObjectId  # <-- Usuario que realizó la venta
  field :delivery_method, type: String #pickup_in_store, delivery

  # Relaciones
  belongs_to :caja, class_name: "Caja", inverse_of: :sales, optional: true
  belongs_to :cajero, class_name: "Cajero", inverse_of: :sales, optional: true
  belongs_to :user, optional: true
  has_many :product_sales, class_name: "ProductSale", inverse_of: :sale, dependent: :destroy
  has_many :devoluciones, class_name: "Devolucion", inverse_of: :sale, dependent: :destroy

  accepts_nested_attributes_for :product_sales, allow_destroy: true

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

  # Productos disponibles para devolución
  def products_available_for_return
    product_sales.select do |ps|
      Devolucion.where(sale_id: id, "sale_devolucion_detalle.product_sale_id": ps.id.to_s).empty?
    end
  end

  def has_products_available_for_return?
    products_available_for_return.any?
  end
end
