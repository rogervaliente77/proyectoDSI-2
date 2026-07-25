class Vehiculo
  include Mongoid::Document
  include Mongoid::Timestamps

  field :numero_correlativo, type: Integer
  field :tipo, type: String
  field :marca, type: String
  field :modelo, type: String
  field :anio, type: String
  field :placa, type: String
  field :consumibles_menores, type: String

  embedded_in :cotizacion
  embeds_many :cotizacion_servicios, class_name: 'CotizacionServicio', cascade_callbacks: true
  embeds_many :repuestos, class_name: 'Repuesto', cascade_callbacks: true

  accepts_nested_attributes_for :cotizacion_servicios, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :repuestos, allow_destroy: true, reject_if: :all_blank
end