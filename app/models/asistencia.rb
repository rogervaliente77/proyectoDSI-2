# app/models/asistencia.rb
class Asistencia
  include Mongoid::Document
  include Mongoid::Timestamps

  field :fecha, type: Date
  field :hora_entrada, type: Time
  field :hora_salida, type: Time
  field :estado, type: String, default: 'Presente' # Presente, Falta Injustificada, Incapacidad, Permiso
  field :observaciones, type: String
  field :justificacion, type: String
  field :es_parcial, type: Boolean, default: false

  belongs_to :empleado

  # Constantes de horario según tu requerimiento
  HORA_ENTRADA_LIMITE = 8
  HORA_SALIDA_ESTANDAR = 17

  # Determina si el día es pagadero
  def dia_pagado?
    # Si es permiso con goce o incapacidad, se paga aunque no esté
    return true if ['Presente', 'Permiso con Goce', 'Incapacidad'].include?(estado)
    # Si es falta injustificada, no se paga
    false
  end

  # Opcional: Calcular si llegó tarde (después de las 8:00 AM)
  def llegada_tardia?
    return false unless hora_entrada
    hora_entrada.hour > HORA_ENTRADA_LIMITE || (hora_entrada.hour == HORA_ENTRADA_LIMITE && hora_entrada.min > 0)
  end
end