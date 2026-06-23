class Asistencia
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :empleado

  field :fecha, type: Date
  field :hora_entrada, type: Time
  field :hora_salida, type: Time
  
  # Estados: 'Asistió', 'Falta', 'Permiso Con Goce', 'Permiso Sin Goce', 'Incapacidad', 'Vacación'
  field :estado, type: String, default: 'Asistió'
  field :observaciones, type: String

  validates :fecha, presence: true
  # Evitar duplicar asistencia del mismo empleado el mismo día
  validates :fecha, uniqueness: { scope: :empleado_id } 
end