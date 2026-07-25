class CotizacionCategoria
  include Mongoid::Document

  field :tipo_mantenimiento, type: String # "PREVENTIVO" o "CORRECTIVO"
  field :categoria, type: String          # "FRENOS", "SISTEMA ELÉCTRICO", etc.
  field :descripcion_tareas, type: String # Texto descriptivo con el alcance

  embeds_many :cotizacion_items, cascade_callbacks: true
  accepts_nested_attributes_for :cotizacion_items, allow_destroy: true

  embedded_in :vehiculo
end