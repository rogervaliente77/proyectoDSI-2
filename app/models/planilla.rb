class Planilla
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre, type: String # Ej: "Quincena del 10 al 25 de Mayo"
  field :tipo_periodo, type: String # 'Semanal', 'Quincenal', 'Mensual'
  field :fecha_desde, type: Date
  field :fecha_hasta, type: Date
  field :fecha_pago, type: Date
  field :procesada, type: Boolean, default: false

  has_many :boletas_de_pago, class_name: "BoletaDePago", dependent: :destroy

  # Validaciones de seguridad requeridas
  validates :nombre, :tipo_periodo, :fecha_desde, :fecha_hasta, presence: true
  validate :validar_periodo_no_futuro
  validate :validar_periodo_no_duplicado

  def generar_planilla!
    return false if procesada
    
    config = ConfiguracionPlanilla.actual
    
    Empleado.where(status: 'Activo').each do |empleado|
      # 1. Determinar Sueldo Base Nominal para el periodo
      sueldo_periodo = calcular_sueldo_base_periodo(empleado)
      
      # Calcular valor de un día y de un minuto para los descuentos
      dias_del_periodo = (fecha_hasta - fecha_desde).to_i + 1
      valor_dia = sueldo_periodo / dias_del_periodo
      valor_minuto = valor_dia / config.horas_laborales_dia / 60.0

      # 2. Buscar asistencias del empleado en este rango de fechas
      asistencias = empleado.asistencias.where(:fecha.gte => fecha_desde, :fecha.lte => fecha_hasta)

      # 3. Contadores para la automatización
      dias_descuento_completo = 0
      total_minutos_tarde_periodo = 0

      asistencias.each do |as|
        case as.estado
        when 'Falta', 'Permiso Sin Goce'
          dias_descuento_completo += 1
        when 'Asistió'
          # Evaluar retraso de entrada (Asumiendo entrada teórica de ejemplo a las 08:00 AM si no hay horario asignado)
          # Lo ideal es comparar contra un estándar. Si registró hora_entrada:
          if as.hora_entrada.present?
            hora_teorica_entrada = Time.zone.parse("#{as.fecha} 08:00:00") # Ajustable a tu horario real
            if as.hora_entrada > hora_teorica_entrada
              total_minutos_tarde_periodo += ((as.hora_entrada - hora_teorica_entrada) / 60).to_i
            end
          end

          # Evaluar salida temprana (Asumiendo salida teórica a las 05:00 PM)
          if as.hora_salida.present?
            hora_teorica_salida = Time.zone.parse("#{as.fecha} 17:00:00")
            if as.hora_salida < hora_teorica_salida
              total_minutos_tarde_periodo += ((hora_teorica_salida - as.hora_salida) / 60).to_i
            end
          end
        end
      end

      # 4. Aplicar Regla de los 30 Minutos de Gracia
      minutos_a_descontar = 0
      if total_minutos_tarde_periodo > config.minutos_gracia_periodo
        # Se descuentan solo los minutos que se pasaron de la gracia
        minutos_a_descontar = total_minutos_tarde_periodo - config.minutos_gracia_periodo
      end

      # 5. Totales de Descuentos
      monto_descuento_faltas = (dias_descuento_completo * valor_dia).round(2)
      monto_descuento_retrasos = (minutos_a_descontar * valor_minuto).round(2)
      total_descuentos_asistencia = monto_descuento_faltas + monto_descuento_retrasos

      # Salario Gravable intermedio
      sueldo_gravable = [sueldo_periodo - total_descuentos_asistencia, 0].max

      # 6. Descuentos de Ley de El Salvador (Sobre lo gravable ajustado)
      techo_isss = tipo_periodo == 'Quincenal' ? (config.isss_techo_salarial / 2) : config.isss_techo_salarial
      monto_isss = ([sueldo_gravable, techo_isss].min * config.isss_porcentaje_empleado).round(2)

      techo_afp = tipo_periodo == 'Quincenal' ? (config.afp_techo_salarial / 2) : config.afp_techo_salarial
      monto_afp = ([sueldo_gravable, techo_afp].min * config.afp_porcentaje_empleado).round(2)

      # Base Renta = Sueldo Gravable - ISSS - AFP
      base_renta = sueldo_gravable - monto_isss - monto_afp
      monto_renta = calcular_renta_sv(base_renta, config).round(2)

      # 7. Crear Boleta de Pago de snapshot
      otros_ing = (empleado.otros_ingresos1 || 0) + (empleado.otros_ingresos2 || 0)
      
      boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
      boleta.update!(
        sueldo_base_momento: sueldo_periodo.round(2),
        dias_trabajados: dias_del_periodo - dias_descuento_completo,
        monto_horas_extra: 0.0,
        otros_ingresos: otros_ing,
        isss_retencion: monto_isss,
        afp_retencion: monto_afp,
        renta_retencion: monto_renta,
        descuento_faltas: total_descuentos_asistencia.round(2),
        prestamos_internos: 0.0,
        total_neto: (sueldo_gravable + otros_ing - monto_isss - monto_afp - monto_renta).round(2)
      )
    end

    update!(procesada: true)
  end

  private

  def calcular_sueldo_base_periodo(empleado)
    case tipo_periodo
    when 'Semanal'
      (empleado.salario_mensual / 4.3333)
    when 'Quincenal'
      empleado.salario_quincenal
    else # Mensual
      empleado.salario_mensual
    end
  end

  def calcular_renta_sv(base, config)
    # Selecciona la tabla de tramos de Renta según el periodo
    tramos = (tipo_periodo == 'Quincenal') ? config.tramos_renta_quincenal : config.tramos_renta_mensual
    tramo = tramos.find { |t| base >= t[:desde] && base <= t[:hasta] }
    tramo ||= tramos.last

    return 0.0 if tramo[:porcentaje] == 0.0
    ((base - (tramo[:sobre_exceso] || 0.0)) * tramo[:porcentaje]) + tramo[:cuota_fija]
  end

  # --- VALIDACIONES DE SEGURIDAD EN BACKEND ---

  def validar_periodo_no_futuro
    if fecha_hasta > Date.today
      errors.add(:fecha_hasta, "No se puede generar una planilla de un periodo futuro o que no ha terminado.")
    end
  end

  def validar_periodo_no_duplicado
    # Evita que existan dos planillas del mismo tipo que se traslapen en fechas
    duplicado = Planilla.where(tipo_periodo: tipo_periodo)
                        .where(:id.ne => self.id)
                        .where(:fecha_desde.lte => fecha_hasta, :fecha_hasta.gte => fecha_desde).exists?
    if duplicado
      errors.add(:base, "Ya existe una planilla generada para este periodo de fechas.")
    end
  end
end