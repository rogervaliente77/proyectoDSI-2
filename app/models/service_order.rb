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

  # Relaciones
  belongs_to :client_car
  
  # Atributos embebidos para servicios y repuestos
  embeds_many :order_services
  embeds_many :order_items

  accepts_nested_attributes_for :order_services, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :all_blank

  # --- VALIDACIONES ---
  validates :numero_orden, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :codigo_orden, presence: true, uniqueness: true
  validates :client_car, presence: true

  # Índices de unicidad en MongoDB
  index({ numero_orden: 1 }, { unique: true })
  index({ codigo_orden: 1 }, { unique: true })

  # --- CALLBACKS ---
  before_validation :preparar_correlativos, on: :create

  # Método público para autocalcular correlativos antes de mostrar en el form (new)
  def preparar_correlativos
    assign_numero_orden
    generate_codigo_orden
  end

  private

  # 1. Asigna el siguiente número correlativo autoincrementable
  def assign_numero_orden
    return if numero_orden.present?

    # Busca la orden con el número más alto registrado y le suma 1
    max_order = ServiceOrder.max(:numero_orden) || 0
    self.numero_orden = max_order + 1
  end

  # 2. Genera el código único con formato: B-MMAA-00001
  def generate_codigo_orden
    return if codigo_orden.present? || numero_orden.blank?

    # Usa la fecha de entrada o la fecha actual como fallback
    base_date = fecha_entrada || Date.current
    mes_anio = base_date.strftime("%m%y") # Ejemplo: 0826
    
    # Rellena el número correlativo a 5 dígitos con ceros a la izquierda
    correlativo = numero_orden.to_s.rjust(5, '0')

    self.codigo_orden = "B-#{mes_anio}-#{correlativo}"
  end
end