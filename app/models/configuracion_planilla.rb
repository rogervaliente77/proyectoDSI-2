class ConfiguracionPlanilla
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre_config, type: String, default: "Configuración General El Salvador"
  
  # --- ISSS ---
  field :isss_porcentaje_empleado, type: Float, default: 0.03 # 3%
  field :isss_techo_salarial, type: Float, default: 1000.00   # Techo actual SV

  # --- AFP ---
  field :afp_porcentaje_empleado, type: Float, default: 0.0725 # 7.25%
  field :afp_techo_salarial, type: Float, default: 7045.06

  # --- DÍAS LABORALES GLOBALES ---
  field :dias_laborales_defecto, type: Array, default: [1, 2, 3, 4, 5] # Lunes a Viernes

  field :minutos_gracia_periodo, type: Integer, default: 30 
  field :horas_laborales_dia, type: Float, default: 8.0     

  # --- FECHAS DE CORTE FIJAS ---
  field :dia_corte_quincena_1, type: Integer, default: 10
  field :dia_corte_quincena_2, type: Integer, default: 25

  # --- TABLA DE RENTA (Convertidas a String Keys para compatibilidad nativa MongoDB) ---
  field :tramos_renta_mensual, type: Array, default: [
    { "desde" => 0.01,   "hasta" => 550.00,  "porcentaje" => 0.0,  "cuota_fija" => 0.0 },
    { "desde" => 550.01, "hasta" => 895.24,  "porcentaje" => 0.10, "cuota_fija" => 17.67, "sobre_exceso" => 550.00 },
    { "desde" => 895.25, "hasta" => 2038.10, "porcentaje" => 0.20, "cuota_fija" => 60.00, "sobre_exceso" => 895.24 },
    { "desde" => 2038.11,"hasta" => 99999.0, "porcentaje" => 0.30, "cuota_fija" => 288.57, "sobre_exceso" => 2038.10 }
  ]

  field :tramos_renta_quincenal, type: Array, default: [
    { "desde" => 0.01,   "hasta" => 275.00,  "porcentaje" => 0.0,  "cuota_fija" => 0.0 },
    { "desde" => 275.01, "hasta" => 447.62,  "porcentaje" => 0.10, "cuota_fija" => 8.83,  "sobre_exceso" => 275.00 },
    { "desde" => 447.63, "hasta" => 1019.05, "porcentaje" => 0.20, "cuota_fija" => 30.00,  "sobre_exceso" => 447.62 },
    { "desde" => 1019.06,"hasta" => 99999.0, "porcentaje" => 0.30, "cuota_fija" => 144.28, "sobre_exceso" => 1019.05 }
  ]

  field :tramos_renta_semanal, type: Array, default: [
    { "desde" => 0.01,   "hasta" => 137.50,  "porcentaje" => 0.0,  "cuota_fija" => 0.0 },
    { "desde" => 137.51, "hasta" => 223.81,  "porcentaje" => 0.10, "cuota_fija" => 4.42,  "sobre_exceso" => 137.50 },
    { "desde" => 223.82, "hasta" => 509.52,  "porcentaje" => 0.20, "cuota_fija" => 15.00, "sobre_exceso" => 223.81 },
    { "desde" => 509.53, "hasta" => 99999.0, "porcentaje" => 0.30, "cuota_fija" => 74.14, "sobre_exceso" => 509.52 }
  ]

  def self.actual
    find_or_create_by(nombre_config: "Configuración General El Salvador")
  end
end