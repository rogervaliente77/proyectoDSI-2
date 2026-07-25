class CotizacionItem
  include Mongoid::Document

  field :nombre, type: String           # Ej: "Pastillas de freno delanteras"
  field :precio, type: Float, default: 0.0
  field :tipo_repuesto, type: String, default: "Original" # Original / Equivalente / N/A
  field :marca_repuesto, type: String   # Ej: "Akebono"
  field :pais_origen, type: String      # Ej: "Japón"

  embedded_in :cotizacion_categoria
end