class Repuesto
  include Mongoid::Document
  include Mongoid::Timestamps

  field :tipo_item, type: String       # "Repuesto" o "Lubricante"
  field :nombre, type: String          # Nombre o descripción del ítem
  field :tipo_origen, type: String     # "Original" o "Equivalente"
  field :marca, type: String
  field :pais_origen, type: String
  field :especificacion, type: String
  field :comentario_uso, type: String

  embedded_in :vehiculo, class_name: 'Vehiculo'
end