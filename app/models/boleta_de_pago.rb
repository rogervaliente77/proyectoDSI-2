class BoletaDePago
  include Mongoid::Document
  include Mongoid::Timestamps # Para created_at y updated_at automáticos
  
  belongs_to :empleado
  belongs_to :planilla

  # Snapshot de valores al momento de generar la planilla
  field :sueldo_base_momento, type: Float
  field :dias_trabajados, type: Integer
  
  # Ingresos
  field :monto_horas_extra, type: Float
  field :otros_ingresos, type: Float
  
  # Descuentos de Ley (SV)
  field :isss_retencion, type: Float
  field :afp_retencion, type: Float
  field :renta_retencion, type: Float
  
  # Otros descuentos (Préstamos, faltas, etc.)
  field :descuento_faltas, type: Float
  field :prestamos_internos, type: Float

  field :total_neto, type: Float # El "Líquido a recibir"
end