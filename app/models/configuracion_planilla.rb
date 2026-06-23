class ConfiguracionPlanilla
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre_config, type: String, default: "Configuración General El Salvador"
  
  # --- ISSS ---
  field :isss_porcentaje_empleado, type: Float, default: 0.03 # 3%
  field :isss_techo_salarial, type: Float, default: 1000.00   # Techo actual SV

  # --- AFP ---
  field :afp_porcentaje_empleado, type: Float, default: 0.0725 # 7.25%
  # En SV el techo cambia o se indexa, pongamos un techo general de ejemplo:
  field :afp_techo_salarial, type: Float, default: 7045.06

  # --- DÍAS LABORALES GLOBALES ---
  # 1 = Lunes, 2 = Martes ..., 7 = Domingo
  field :dias_laborales_defecto, type: Array, default: [1, 2, 3, 4, 5] # Lunes a Sábado

  field :minutos_gracia_periodo, type: Integer, default: 30 # Tus 30 minutos de gracia
  field :horas_laborales_dia, type: Float, default: 8.0     # Jornada estándar SV

  # --- FECHAS DE CORTE FIJAS ---
  # El día del mes en que se cierra la planilla
  field :dia_corte_quincena_1, type: Integer, default: 10
  field :dia_corte_quincena_2, type: Integer, default: 25

  # --- TABLA DE RENTA (Quincenal / Mensual) ---
  # Guardaremos los tramos como un Array de Hashes dentro de MongoDB
  field :tramos_renta_mensual, type: Array, default: [
    { desde: 0.01,   hasta: 472.00,  porcentaje: 0.0,  cuota_fija: 0.0 },
    { desde: 472.01, hasta: 895.24,  porcentaje: 0.10, cuota_fija: 17.67, sobre_exceso: 472.00 },
    { desde: 895.25, hasta: 2038.10, porcentaje: 0.20, cuota_fija: 60.00, sobre_exceso: 895.24 },
    { desde: 2038.11, hasta: 99999.0, porcentaje: 0.30, cuota_fija: 288.57, sobre_exceso: 2038.10 }
  ]

  field :tramos_renta_quincenal, type: Array, default: [
    { desde: 0.01,   hasta: 236.00,  porcentaje: 0.0,  cuota_fija: 0.0 },
    { desde: 236.01, hasta: 447.62,  porcentaje: 0.10, cuota_fija: 8.83,  sobre_exceso: 236.00 },
    { desde: 447.63, hasta: 1019.05, porcentaje: 0.20, cuota_fija: 30.00,  sobre_exceso: 447.62 },
    { desde: 1019.06, hasta: 99999.0, porcentaje: 0.30, cuota_fija: 144.28, sobre_exceso: 1019.06 }
  ]

  # Método de conveniencia para obtener la configuración activa
  def self.actual
    find_or_create_by(nombre_config: "Configuración General El Salvador")
  end
end