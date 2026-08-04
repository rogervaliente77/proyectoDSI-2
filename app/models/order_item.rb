class OrderItem
  include Mongoid::Document

  field :tipo, type: String # 'Repuesto', 'Lubricante', 'Otro'
  field :descripcion, type: String
  field :cantidad, type: Integer, default: 1
  field :precio_unitario, type: Float, default: 0.0
  field :precio_total, type: Float, default: 0.0

  embedded_in :service_order
end