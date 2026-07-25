class CotizacionServicio
  include Mongoid::Document
  include Mongoid::Timestamps

  field :tipo_mantenimiento, type: String # "Preventivo" o "Correctivo"
  field :sistema, type: String            # Nombre de la categoría
  field :servicio_descripcion, type: String
  field :precio, type: Float, default: 0.0

  embedded_in :vehiculo, class_name: 'Vehiculo'
end