class Planilla
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre, type: String # Ej: "Quincena del 10 al 25 de Mayo"
  field :tipo_periodo, type: String # 'Semanal', 'Quincenal', 'Mensual'
  field :tipo_planilla, type: String, default: 'Salarial Ordinaria'
  field :fecha_desde, type: Date
  field :fecha_hasta, type: Date
  field :fecha_pago, type: Date
  field :procesada, type: Boolean, default: false

  has_many :boletas_de_pago, class_name: "BoletaDePago", dependent: :destroy

  # Validaciones de seguridad requeridas
  validates :nombre, :tipo_periodo, :fecha_desde, :fecha_hasta, presence: true
  validate :validar_periodo_no_futuro, unless: -> { tipo_planilla == 'Aguinaldo' }
  validate :validar_periodo_no_duplicado

  before_validation :configurar_fechas_aguinaldo, if: -> { tipo_planilla == 'Aguinaldo' }

  # =========================================================================
  # UNICO MÉTODO GOBERNANTE: GENERACIÓN DE PLANILLAS ORDINARIAS
  # =========================================================================
  def generar_planilla!
    return false if procesada
    if tipo_planilla == 'Aguinaldo'
      return generar_aguinaldo!
    end
    
    config = ConfiguracionPlanilla.actual
    
    Empleado.where(status: 'Activo').each do |empleado|
      # -------------------------------------------------------------------------
      # MANEJO ESPECIAL: PLANILLA DE QUINCENA 25
      # Exenta de descuentos de ley (ISSS, AFP, ISR) y de asistencia por ley especial.
      # -------------------------------------------------------------------------
      # -------------------------------------------------------------------------
      # MANEJO ESPECIAL: PLANILLA DE QUINCENA 25
      # Exenta de descuentos de ley (ISSS, AFP, ISR) y de asistencia por ley especial.
      # -------------------------------------------------------------------------
      if tipo_planilla == 'Quincena 25'
        # Fijamos como fecha pivote estricta el 15 de enero del año actual de la planilla
        fecha_pivote = Date.new(self.fecha_hasta.year, 1, 15)

        # Regla 1: Si ingresó después del 15 de enero del año actual, NO ENTRA
        next if empleado.fecha_inicio_trabajo.nil? || empleado.fecha_inicio_trabajo > fecha_pivote

        # Filtro de techo salarial para aplicar al beneficio
        if (empleado.salario_mensual || 0.0) <= 1500.0
          monto_q25 = empleado.salario_mensual * 0.50
          
          # Determinamos la antigüedad tomando como límite el 15 de enero del año actual
          un_ano_atras_desde_pivote = fecha_pivote - 1.year
          
          if empleado.fecha_inicio_trabajo > un_ano_atras_desde_pivote
            # Regla 2: Tiene menos de un año al 15 de enero -> Pago Proporcional basado en meses exactos
            dias_trabajados = (fecha_pivote - empleado.fecha_inicio_trabajo).to_i + 1
            
            # Calculamos los meses con precisión flotante
            meses_laborados = (dias_trabajados / 30.4167)
            
            # Acotamos los meses entre 1 y 12 por seguridad matemática
            meses_laborados = [1.0, [meses_laborados, 12.0].min].max
            
            # Aplicamos la fórmula: (meses / 12) * (salario * 0.5)
            monto_q25 = (meses_laborados / 12.0) * monto_q25
          end
          
          # Extracción y limpieza de movimientos del periodo asignado a la planilla
          movimientos_periodo = empleado.movimientos_planilla.where(
            fecha: fecha_desde..fecha_hasta,
            procesado: false
          )
          total_viaticos = movimientos_periodo.where(tipo: 'Viatico').sum(:monto) || 0.0
          total_bonos_comisiones = movimientos_periodo.where(tipo: %w[Bono Comision]).sum(:monto) || 0.0

          # Escritura limpia en la base de datos de MongoDB
          boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
          boleta.update!(
            sueldo_base_momento: monto_q25.round(2),
            dias_trabajados: 15,
            monto_horas_extra: total_bonos_comisiones.round(2),
            otros_ingresos: total_viaticos.round(2),
            isss_retencion: 0.0,
            afp_retencion: 0.0,
            renta_retencion: 0.0,
            descuento_faltas: 0.0,
            descuento_retrasos: 0.0,
            prestamos_internos: 0.0,
            total_neto: (monto_q25 + total_bonos_comisiones + total_viaticos).round(2)
          )
          movimientos_periodo.update_all(procesado: true, planilla_id: self.id)
        end
        next
      end
      # -------------------------------------------------------------------------

      sueldo_periodo = calcular_sueldo_base_periodo(empleado)
      
      # Base comercial adaptada para Semanal, Quincenal o Mensual en El Salvador
      dias_base_calculo = case tipo_periodo
                          when 'Semanal'   then 7.0
                          when 'Quincenal' then 15.0
                          else 30.0 # Mensual
                          end

      valor_dia = sueldo_periodo / dias_base_calculo
      valor_hora = valor_dia / config.horas_laborales_dia
      valor_minuto = valor_hora / 60.0
  
      dias_del_periodo = (fecha_hasta - fecha_desde).to_i + 1
  
      rango_fechas = fecha_desde.beginning_of_day..fecha_hasta.end_of_day
      asistencias = empleado.asistencias.where(fecha: rango_fechas)
  
      # Extractor de Movimientos Manuales
      movimientos_periodo = empleado.movimientos_planilla.where(
        fecha: fecha_desde..fecha_hasta,
        procesado: false
      )
  
      total_bonos              = movimientos_periodo.where(tipo: 'Bono').sum(:monto) || 0.0
      total_comisiones         = movimientos_periodo.where(tipo: 'Comision').sum(:monto) || 0.0
      total_viaticos           = movimientos_periodo.where(tipo: 'Viatico').sum(:monto) || 0.0
      total_descuentos_manuales = movimientos_periodo.where(tipo: 'Descuento').sum(:monto) || 0.0
  
      # REGLA: Si no hay asistencias en el periodo seleccionado
      if asistencias.empty?
        sueldo_gravable_vacio = [sueldo_periodo + total_bonos + total_comisiones, 0].max
  
        # Adaptación de techos en base vacía
        techo_isss_vacio = case tipo_periodo
                           when 'Semanal'   then (config.isss_techo_salarial / 30.0) * 7.0
                           when 'Quincenal' then config.isss_techo_salarial / 2.0
                           else config.isss_techo_salarial
                           end
        monto_isss_vacio = ([sueldo_gravable_vacio, techo_isss_vacio].min * config.isss_porcentaje_empleado).round(2)
  
        techo_afp_vacio = case tipo_periodo
                          when 'Semanal'   then (config.afp_techo_salarial / 30.0) * 7.0
                          when 'Quincenal' then config.afp_techo_salarial / 2.0
                          else config.afp_techo_salarial
                          end
        monto_afp_vacio = ([sueldo_gravable_vacio, techo_afp_vacio].min * config.afp_porcentaje_empleado).round(2)
  
        # Cálculo DIRECTO utilizando el período real sin alterar montos
        base_renta_vacia = [sueldo_gravable_vacio - monto_isss_vacio - monto_afp_vacio, 0].max
        monto_renta_vacio = calcular_renta_con_tramos(base_renta_vacia, config, tipo_periodo).round(2)
  
        otros_ing_vacio = total_viaticos
  
        boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
        boleta.update!(
          sueldo_base_momento: sueldo_periodo.round(2),
          dias_trabajados: dias_del_periodo,
          monto_horas_extra: (total_bonos + total_comisiones).round(2),
          otros_ingresos: otros_ing_vacio,
          isss_retencion: monto_isss_vacio,
          afp_retencion: monto_afp_vacio,
          renta_retencion: monto_renta_vacio,
          descuento_faltas: total_descuentos_manuales,
          descuento_retrasos: 0.0,
          prestamos_internos: 0.0,
          total_neto: (sueldo_gravable_vacio + otros_ing_vacio - monto_isss_vacio - monto_afp_vacio - monto_renta_vacio - total_descuentos_manuales).round(2)
        )
  
        movimientos_periodo.update_all(procesado: true, planilla_id: self.id)
        next 
      end
  
      # Procesamiento diario de marcaciones (Contadores analíticos)
      dias_descuento_completo = 0
      total_minutos_tarde_periodo = 0
      monto_total_horas_extra = 0.0
      
      fechas_con_registro = asistencias.map { |a| a.fecha.to_date }
      dias_laborales_empleado = empleado.dias_laborales
  
      (fecha_desde..fecha_hasta).each do |dia_evaluado|
        wday_ajustado = (dia_evaluado.wday == 0) ? 7 : dia_evaluado.wday
        es_dia_laboral = dias_laborales_empleado.include?(wday_ajustado)
  
        if es_dia_laboral && !fechas_con_registro.include?(dia_evaluado)
          dias_descuento_completo += 1
          next
        end
  
        as = asistencias.find { |a| a.fecha.to_date == dia_evaluado }
        if as.present?
          case as.estado
          when 'Falta', 'Permiso Sin Goce'
            dias_descuento_completo += 1
          when 'Asistió'
            if as.hora_entrada.present?
              limite_entrada = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 8, 0, 0)
              reg_entrada = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, as.hora_entrada.hour, as.hora_entrada.min, 0)
              if reg_entrada > limite_entrada
                total_minutos_tarde_periodo += ((reg_entrada - limite_entrada) / 60).to_i
              end
            end
  
            if as.hora_salida.present?
              limite_salida = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 17, 0, 0)
              reg_salida = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, as.hora_salida.hour, as.hora_salida.min, 0)
              
              if reg_salida < limite_salida
                total_minutos_tarde_periodo += ((limite_salida - reg_salida) / 60).to_i
              elsif reg_salida > limite_salida
                inicio_he = limite_salida
                fin_he = reg_salida
                limite_nocturno = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 19, 0, 0)
                
                horas_extra_diurnas = 0.0
                horas_extra_nocturnas = 0.0
                
                if fin_he <= limite_nocturno
                  horas_extra_diurnas = (fin_he - inicio_he) / 3600.0
                else
                  horas_extra_diurnas = (limite_nocturno - inicio_he) / 3600.0
                  horas_extra_nocturnas = (fin_he - limite_nocturno) / 3600.0
                end
                monto_total_horas_extra += (horas_extra_diurnas * valor_hora * 2.0)
                monto_total_horas_extra += (horas_extra_nocturnas * valor_hora * 2.0 * 1.25)
              end
            end
          end
        end
      end
  
      minutos_a_descontar = total_minutos_tarde_periodo > config.minutos_gracia_periodo ? total_minutos_tarde_periodo : 0
      monto_descuento_faltas = (dias_descuento_completo * valor_dia).round(2)
      monto_descuento_retrasos = (minutos_a_descontar * valor_minuto).round(2)
      
      ingresos_adicionales_imponibles = monto_total_horas_extra + total_bonos + total_comisiones
      
      # 1. SUMA DEL SUELDO BASE DEL PERIODO + ADICIONALES - DESCUENTOS POR ASISTENCIA
      sueldo_gravable = [sueldo_periodo - monto_descuento_faltas - monto_descuento_retrasos + ingresos_adicionales_imponibles, 0].max
  
      # 2. CALCULAR AFP E ISSS CON SUS TECHOS PROPORCIONALES AL PERIODO CORRIENTE
      techo_isss = case tipo_periodo
                   when 'Semanal'   then (config.isss_techo_salarial / 30.0) * 7.0
                   when 'Quincenal' then config.isss_techo_salarial / 2.0
                   else config.isss_techo_salarial
                   end
      monto_isss = ([sueldo_gravable, techo_isss].min * config.isss_porcentaje_empleado).round(2)
  
      techo_afp = case tipo_periodo
                  when 'Semanal'   then (config.afp_techo_salarial / 30.0) * 7.0
                  when 'Quincenal' then config.afp_techo_salarial / 2.0
                  else config.afp_techo_salarial
                  end
      monto_afp = ([sueldo_gravable, techo_afp].min * config.afp_porcentaje_empleado).round(2)
  
      # 3. BASE IMPONIBLE DE RENTA DIRECTA REAL
      base_renta = [sueldo_gravable - monto_isss - monto_afp, 0].max
      
      # 4. CALCULO EVALUANDO DIRECTAMENTE LA BASE EN LAS TABLAS DEL PERIODO CORRESPONDIENTE
      monto_renta = calcular_renta_con_tramos(base_renta, config, tipo_periodo).round(2)
  
      otros_ing = total_viaticos
      descuentos_totales_faltas = monto_descuento_faltas + total_descuentos_manuales
  
      boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
      boleta.update!(
        sueldo_base_momento: sueldo_periodo.round(2),
        dias_trabajados: [dias_del_periodo - dias_descuento_completo, 0].max,
        monto_horas_extra: ingresos_adicionales_imponibles.round(2),
        otros_ingresos: otros_ing.round(2),
        isss_retencion: monto_isss,                      
        afp_retencion: monto_afp,                        
        renta_retencion: monto_renta,                    
        descuento_faltas: descuentos_totales_faltas.round(2),
        descuento_retrasos: monto_descuento_retrasos,     
        prestamos_internos: 0.0,
        total_neto: (sueldo_gravable + otros_ing - monto_isss - monto_afp - monto_renta - total_descuentos_manuales).round(2)
      )
  
      movimientos_periodo.update_all(procesado: true, planilla_id: self.id)
    end
  
    update!(procesada: true)
  end

  # =========================================================================
  # GESTIÓN EXCLUSIVA DE AGUINALDOS (Art. 196+ Código de Trabajo)
  # =========================================================================
  def generar_aguinaldo!
    return false if procesada
    config = ConfiguracionPlanilla.actual
    monto_exento_renta_aguinaldo = 1500.00 
  
    ano_actual = Date.current.year
    fecha_corte_aguinaldo = Date.new(ano_actual, 10, 20) 
  
    Empleado.where(status: 'Activo').each do |empleado|
      next if empleado.fecha_inicio_trabajo.nil? || empleado.fecha_inicio_trabajo > fecha_corte_aguinaldo
  
      dias_totales_servicio = (fecha_corte_aguinaldo - empleado.fecha_inicio_trabajo).to_i
      
      inicio_ano_o_ingreso = [Date.new(ano_actual, 1, 1), empleado.fecha_inicio_trabajo].max
      dias_trabajados_este_ano = (fecha_corte_aguinaldo - inicio_ano_o_ingreso).to_i + 1
  
      salario_mensual_emp = empleado.salario_mensual || 0.0
      salario_diario = salario_mensual_emp / 30.0
      dias_aguinaldo = 0
  
      if dias_totales_servicio >= 3652
        dias_aguinaldo = 21.0
      elsif dias_totales_servicio >= 1096
        dias_aguinaldo = 19.0
      elsif dias_totales_servicio >= 365
        dias_aguinaldo = 15.0
      else
        dias_aguinaldo = (dias_trabajados_este_ano * 15.0) / 365.0
      end
  
      monto_aguinaldo = (dias_aguinaldo * salario_diario).round(2)
  
      monto_isss = 0.0
      monto_afp = 0.0
      monto_renta = 0.0
  
      if monto_aguinaldo > monto_exento_renta_aguinaldo
        excedente_renta = monto_aguinaldo - monto_exento_renta_aguinaldo
        monto_renta = calcular_renta_sv(excedente_renta, config).round(2)
      end
  
      boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
      boleta.update!(
        sueldo_base_momento: salario_mensual_emp.round(2),
        dias_trabajados: dias_totales_servicio >= 365 ? 30 : [dias_trabajados_este_ano, 30].min,
        monto_horas_extra: 0.0,
        otros_ingresos: monto_aguinaldo, 
        isss_retencion: monto_isss,
        afp_retencion: monto_afp,
        renta_retencion: monto_renta,
        descuento_faltas: 0.0,
        descuento_retrasos: 0.0,
        prestamos_internos: 0.0,
        total_neto: (monto_aguinaldo - monto_renta).round(2)
      )
    end
  
    update!(procesada: true)
  end

  private

  def configurar_fechas_aguinaldo
    ano_actual = Time.now.year
    self.tipo_periodo = 'Mensual' 
    self.fecha_desde = Date.new(ano_actual, 1, 1)
    self.fecha_hasta = Date.new(ano_actual, 12, 12) 
    self.fecha_pago  = Date.new(ano_actual, 12, 12) if self.fecha_pago.blank?
  end

  def calcular_sueldo_base_periodo(empleado)
    case tipo_periodo
    when 'Semanal'
      (empleado.salario_mensual / 4.3333)
    when 'Quincenal'
      empleado.respond_to?(:salario_quincenal) && empleado.salario_quincenal.to_f > 0 ? empleado.salario_quincenal : (empleado.salario_mensual / 2.0)
    else # Mensual
      empleado.salario_mensual
    end
  end

  # EVALUACIÓN DIRECTA DE LOS ARRAYS DE MONGOID SEGÚN EL PERIODO
  def calcular_renta_con_tramos(base_imponible, config, periodo_evaluado)
    # 1. Aseguramos que sea string, sin espacios y en minúsculas
    periodo = periodo_evaluado.to_s.strip.downcase

    # 2. Extraemos los tramos crudos de la configuración
    tramos_crudos = case periodo
                    when 'semanal'   then config.tramos_renta_semanal
                    when 'quincenal' then config.tramos_renta_quincenal
                    when 'mensual'   then config.tramos_renta_mensual
                    else 
                      config.tramos_renta_mensual
                    end

    # 3. CRUCIAL: Convertimos los hashes de MongoDB para que acepten tanto strings como símbolos
    tramos = Array(tramos_crudos).map(&:with_indifferent_access)

    # 4. Buscamos el tramo correspondiente de manera segura
    tramo_actual = tramos.find { |t| base_imponible >= t[:desde].to_f && base_imponible <= t[:hasta].to_f }
    tramo_actual ||= tramos.last 

    return 0.0 if tramo_actual.nil? || tramo_actual[:porcentaje].to_f == 0.0

    # 5. Extraemos los valores convirtiéndolos a float por seguridad
    porcentaje   = tramo_actual[:porcentaje].to_f
    cuota_fija   = tramo_actual[:cuota_fija].to_f
    sobre_exceso = tramo_actual[:sobre_exceso].to_f

    # 6. Aplicamos la fórmula legal de El Salvador
    monto_renta = ((base_imponible - sobre_exceso) * porcentaje) + cuota_fija
    monto_renta
  end

  def calcular_renta_sv(base, config)
    calcular_renta_con_tramos(base, config, 'Mensual')
  end

  # --- VALIDACIONES DE SEGURIDAD EN BACKEND ---

  def validar_periodo_no_futuro
    if fecha_hasta > Date.today
      errors.add(:fecha_hasta, "No se puede generar una planilla de un periodo futuro o que no ha terminado.")
    end
  end

  def validar_periodo_no_duplicado
    duplicado = Planilla.where(tipo_periodo: tipo_periodo, tipo_planilla: tipo_planilla)
                        .where(:id.ne => self.id)
                        .where(:fecha_desde.lte => fecha_hasta, :fecha_hasta.gte => fecha_desde).exists?
    if duplicado
      errors.add(:base, "Ya existe una planilla de tipo #{tipo_planilla} generada para este rango de fechas.")
    end
  end

end