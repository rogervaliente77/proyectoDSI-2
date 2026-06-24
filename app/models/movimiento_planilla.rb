class MovimientoPlanilla
  include Mongoid::Document
  include Mongoid::Timestamps

  # Relaciones
  belongs_to :empleado
  belongs_to :planilla, optional: true # Se llena automáticamente cuando una planilla lo absorbe

  # Campos
  field :tipo, type: String          # 'Bono', 'Viatico', 'Comision', 'Descuento'
  field :monto, type: Float
  field :fecha, type: Date
  field :descripcion, type: String, default: ""
  field :procesado, type: Boolean, default: false

  # Validaciones
  validates_presence_of :tipo, :monto, :fecha
  validates_inclusion_of :tipo, in: %w(Bono Viatico Comision Descuento)
  validates_numericality_of :monto, greater_than: 0

  # Scopes para facilitar las consultas
  scope :ingresos, -> { where(:tipo.in => ['Bono', 'Viatico', 'Comision']) }
  scope :egresos, -> { where(tipo: 'Descuento') }
  scope :pendientes, -> { where(procesado: false) }
end