class ServiceOrder
  include Mongoid::Document
  include Mongoid::Timestamps

  field :numero_orden, type: Integer
  field :fecha_entrada, type: Date
  field :fecha_salida, type: Date
  field :km_entrada, type: String
  field :km_salida, type: String
  field :tecnico, type: String
  field :forma_pago, type: String
  field :subtotal, type: Float, default: 0.0
  field :total, type: Float, default: 0.0

  belongs_to :client_car
  
  # Atributos embebidos para servicios y repuestos
  embeds_many :order_services
  embeds_many :order_items

  accepts_nested_attributes_for :order_services, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank
end