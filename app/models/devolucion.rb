# app/models/devolucion.rb
class Devolucion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id, type: BSON::ObjectId
  field :client_name, type: String
  field :sale_devolucion_detalle, type: Array, default: [] 
  # Estructura del detalle:
  # [
  #   {
  #     "product_id" => "...",
  #     "cantidad" => 1,
  #     "precio_unitario" => 10.0,
  #     "descuento" => 0.0,
  #     "precio_con_descuento" => 10.0,
  #     "condicion" => "defectuoso" # o "buen_estado"
  #   }
  # ]

  field :fecha_devolucion, type: DateTime
  field :comments_devolucion, type: String
  field :total_a_devolver, type: Float, default: 0.0
  field :tipo_devolucion, type: String, default: "parcial" # "parcial" o "total"
  field :is_authorized, type: Boolean, default: false
  field :authorized_at, type: DateTime

  # Relaciones
  belongs_to :caja, class_name: "Caja", inverse_of: :devoluciones, optional: true
  belongs_to :cajero, class_name: "Cajero", inverse_of: :devoluciones, optional: true
  belongs_to :sale, class_name: "Sale", inverse_of: :devoluciones
  has_many :returned_products, dependent: :destroy

  before_save :determinar_tipo_devolucion

  # Calcular total según los productos y cantidades seleccionadas
  def calcular_total
    total = 0.0
    (sale_devolucion_detalle || []).each do |item|
      precio = item['precio_con_descuento'].present? ? item['precio_con_descuento'].to_f : item['precio_unitario'].to_f
      total += precio * item['cantidad'].to_i
    end
    self.total_a_devolver = total.round(2)
  end

  private

  def determinar_tipo_devolucion
    return unless sale.present?
    
    # Evalúa si la devolución actual junto con previas autorizadas cubre la venta completa
    monto_acumulado = sale.total_devuelto + total_a_devolver
    self.tipo_devolucion = monto_acumulado >= sale.total_amount ? "total" : "parcial"
  end
end