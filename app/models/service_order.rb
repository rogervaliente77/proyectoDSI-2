class ServiceOrder
  include Mongoid::Document
  include Mongoid::Timestamps

  field :numero_orden, type: Integer
  field :codigo_orden, type: String
  field :fecha_entrada, type: Date
  field :fecha_salida, type: Date
  field :km_entrada, type: String
  field :km_salida, type: String
  field :tecnico, type: String
  field :forma_pago, type: String
  field :subtotal, type: Float, default: 0.0
  field :total, type: Float, default: 0.0

  # Campos de asociación operativa
  field :caja_id, type: BSON::ObjectId
  field :sucursal_id, type: BSON::ObjectId
  field :cajero_id, type: BSON::ObjectId
  field :tipo_documento_dte_id, type: BSON::ObjectId
  field :condicion_tributaria, type: String, default: "gravado"

  # Relaciones
  belongs_to :client_car
  belongs_to :caja, optional: true
  belongs_to :cajero, class_name: "Cajero", optional: true
  belongs_to :sucursal, optional: true
  belongs_to :user, optional: true
  belongs_to :tipo_documento_dte, class_name: "TipoDocumentoDte", optional: true
  
  has_one :head_movimiento_caja, dependent: :nullify

  # Atributos embebidos
  embeds_many :order_services
  embeds_many :order_items

  accepts_nested_attributes_for :order_services, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  # Validaciones
  validates :numero_orden, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :codigo_orden, presence: true, uniqueness: true
  validates :client_car, presence: true

  # Callbacks
  before_validation :preparar_correlativos, on: :create

  def preparar_correlativos
    assign_numero_orden
    generate_codigo_orden
  end

  private

  def assign_numero_orden
    return if numero_orden.present?
    max_order = ServiceOrder.max(:numero_orden) || 0
    self.numero_orden = max_order + 1
  end

  def generate_codigo_orden
    return if codigo_orden.present? || numero_orden.blank?
    base_date = fecha_entrada || Date.current
    mes_anio = base_date.strftime("%m%y")
    correlativo = numero_orden.to_s.rjust(5, '0')
    self.codigo_orden = "B-#{mes_anio}-#{correlativo}"
  end
end