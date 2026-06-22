class Planilla
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre, type: String # Ej: "Primera Quincena Mayo 2026"
  
  # Clasificación de la planilla
  # Valores sugeridos: 'Semanal', 'Quincenal', 'Mensual', 'Extraordinaria'
  field :tipo_periodo, type: String 
  
  field :fecha_desde, type: Date
  field :fecha_hasta, type: Date
  field :fecha_pago, type: Date

  has_many :boletas_de_pago, class_name: "BoletaDePago"
end