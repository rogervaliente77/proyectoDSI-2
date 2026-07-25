class Cotizacion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :numero_cotizacion, type: String
  field :cliente_nombre, type: String
  field :anio_licitacion, type: String
  field :plazo_entrega, type: String
  field :lugar_entrega, type: String
  field :condiciones_pago_preventivo, type: String
  field :condiciones_pago_correctivo, type: String

  embeds_many :vehiculos, class_name: 'Vehiculo', cascade_callbacks: true

  accepts_nested_attributes_for :vehiculos, allow_destroy: true, reject_if: :all_blank
end