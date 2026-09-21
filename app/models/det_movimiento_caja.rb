class DetMovimientoCaja
  include Mongoid::Document
  include Mongoid::Timestamps

  field :product_id, type: BSON::ObjectId     # ID del producto o servicio
  field :item_nombre, type: String             # Nombre del ítem/servicio
  field :tipo_item, type: String, default: "producto" # "producto" o "servicio"
  field :cantidad, type: Float, default: 1.0
  field :precio_unitario, type: Float, default: 0.0
  field :descuento, type: Float, default: 0.0
  
  # Clasificación tributaria del detalle
  field :condicion_tributaria, type: String, default: "gravado" # "gravado", "exento", "no_sujeta"
  field :subtotal, type: Float, default: 0.0

  belongs_to :head_movimiento_caja, class_name: "HeadMovimientoCaja", inverse_of: :det_movimientos_caja
end