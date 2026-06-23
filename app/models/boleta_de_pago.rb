class BoletaDePago
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :planilla
  belongs_to :empleado

  field :sueldo_base_momento, type: Float, default: 0.0
  field :dias_trabajados, type: Integer, default: 0
  field :monto_horas_extra, type: Float, default: 0.0
  field :otros_ingresos, type: Float, default: 0.0
  field :isss_retencion, type: Float, default: 0.0
  field :afp_retencion, type: Float, default: 0.0
  field :renta_retencion, type: Float, default: 0.0
  field :descuento_faltas, type: Float, default: 0.0 # Guarda Faltas + Minutos tarde de gracia
  field :prestamos_internos, type: Float, default: 0.0
  field :total_neto, type: Float, default: 0.0
end