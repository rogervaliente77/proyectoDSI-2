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

  # def generar_planilla!
  #   return false if procesada
    
  #   config = ConfiguracionPlanilla.actual
    
  #   Empleado.where(status: 'Activo').each do |empleado|
  #     # 1. Determinar Sueldo Base Nominal para el periodo
  #     sueldo_periodo = calcular_sueldo_base_periodo(empleado)
      
  #     # Calcular valores proporcionales para el periodo
  #     dias_del_periodo = (fecha_hasta - fecha_desde).to_i + 1
  #     valor_dia = sueldo_periodo / dias_del_periodo
  #     valor_hora = valor_dia / config.horas_laborales_dia
  #     valor_minuto = valor_hora / 60.0
  
  #     # 2. Buscar asistencias en el rango de fechas
  #     rango_fechas = fecha_desde.beginning_of_day..fecha_hasta.end_of_day
  #     asistencias = empleado.asistencias.where(fecha: rango_fechas)
  
  #     # 3. Contadores analíticos
  #     dias_descuento_completo = 0
  #     total_minutos_tarde_periodo = 0
      
  #     # NUEVOS CONTADORES MONETARIOS
  #     monto_total_horas_extra = 0.0
  #     monto_total_recargo_nocturno = 0.0
      
  #     fechas_con_registro = asistencias.map { |a| a.fecha.to_date }
  #     dias_laborales_empleado = empleado.dias_laborales
  
  #     # Evaluamos día por día
  #     (fecha_desde..fecha_hasta).each do |dia_evaluado|
  #       wday_ajustado = (dia_evaluado.wday == 0) ? 7 : dia_evaluado.wday
  #       es_dia_laboral = dias_laborales_empleado.include?(wday_ajustado)
  
  #       # Falta automática si no hay registro en día laboral
  #       if es_dia_laboral && !fechas_con_registro.include?(dia_evaluado)
  #         dias_descuento_completo += 1
  #         next
  #       end
  
  #       as = asistencias.find { |a| a.fecha.to_date == dia_evaluado }
  #       if as.present?
  #         case as.estado
  #         when 'Falta', 'Permiso Sin Goce'
  #           dias_descuento_completo += 1
  #         when 'Asistió'
  #           # --- EVALUACIÓN DE ENTRADA (RETRASOS) ---
  #           if as.hora_entrada.present?
  #             limite_entrada = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 8, 0, 0)
  #             reg_entrada = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, as.hora_entrada.hour, as.hora_entrada.min, 0)
              
  #             if reg_entrada > limite_entrada
  #               total_minutos_tarde_periodo += ((reg_entrada - limite_entrada) / 60).to_i
  #             end
  #           end
  
  #           # --- EVALUACIÓN DE SALIDA (SALIDA TEMPRANA / HORAS EXTRA / NOCTURNAS) ---
  #           if as.hora_salida.present?
  #             limite_salida = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 17, 0, 0) # 05:00 PM
  #             reg_salida = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, as.hora_salida.hour, as.hora_salida.min, 0)
              
  #             if reg_salida < limite_salida
  #               # Salió antes de las 5:00 PM (Acumula retraso)
  #               total_minutos_tarde_periodo += ((limite_salida - reg_salida) / 60).to_i
  #             elsif reg_salida > limite_salida
  #               # ¡HIZO HORAS EXTRA! Salió después de las 5:00 PM
  #               inicio_he = limite_salida
  #               fin_he = reg_salida
                
  #               # Definimos el umbral donde empieza el horario nocturno en El Salvador (07:00 PM)
  #               limite_nocturno = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 19, 0, 0)
                
  #               horas_extra_diurnas = 0.0
  #               horas_extra_nocturnas = 0.0
                
  #               if fin_he <= limite_nocturno
  #                 # Caso A: Se quedó extra pero se fue antes o justo a las 7:00 PM (Todo es extra diurno)
  #                 horas_extra_diurnas = (fin_he - inicio_he) / 3600.0
  #               else
  #                 # Caso B: Se quedó pasado de las 7:00 PM (Tiene una parte diurna y otra nocturna)
  #                 horas_extra_diurnas = (limite_nocturno - inicio_he) / 3600.0
  #                 horas_extra_nocturnas = (fin_he - limite_nocturno) / 3600.0
  #               end
                
  #               # Calculamos el dinero de las Horas Extra:
  #               # Diurna = Valor Hora * 2 (Recargo del 100%)
  #               monto_total_horas_extra += (horas_extra_diurnas * valor_hora * 2.0)
                
  #               # Nocturna = Valor Hora * 2 (por ser extra) * 1.25 (por recargo nocturno del 25%)
  #               monto_total_horas_extra += (horas_extra_nocturnas * valor_hora * 2.0 * 1.25)
  #             end
  #           end
  #         end
  #       end
  #     end
  
  #     # 4. Regla de los Minutos de Gracia para retrasos
  #     minutos_a_descontar = 0
  #     if total_minutos_tarde_periodo > config.minutos_gracia_periodo
  #       minutos_a_descontar = total_minutos_tarde_periodo - config.minutos_gracia_periodo
  #     end
  
  #     # 5. Totales de Descuentos por Asistencia
  #     monto_descuento_faltas = (dias_descuento_completo * valor_dia).round(2)
  #     monto_descuento_retrasos = (minutos_a_descontar * valor_minuto).round(2)
  #     total_descuentos_asistencia = monto_descuento_faltas + monto_descuento_retrasos
  
  #     # --- NUEVO SALARIO GRAVABLE ---
  #     # Base Gravable = Sueldo Base + Horas Extra - Descuentos de Asistencia
  #     sueldo_gravable = [sueldo_periodo + monto_total_horas_extra - total_descuentos_asistencia, 0].max
  
  #     # 6. Descuentos de Ley de El Salvador (Sobre la nueva base que ya incluye horas extra)
  #     techo_isss = tipo_periodo == 'Quincenal' ? (config.isss_techo_salarial / 2) : config.isss_techo_salarial
  #     monto_isss = ([sueldo_gravable, techo_isss].min * config.isss_porcentaje_empleado).round(2)
  
  #     techo_afp = tipo_periodo == 'Quincenal' ? (config.afp_techo_salarial / 2) : config.afp_techo_salarial
  #     monto_afp = ([sueldo_gravable, techo_afp].min * config.afp_porcentaje_empleado).round(2)
  
  #     base_renta = sueldo_gravable - monto_isss - monto_afp
  #     monto_renta = calcular_renta_sv(base_renta, config).round(2)
  
  #     # 7. Registrar/Actualizar Boleta de Pago
  #     otros_ing = (empleado.otros_ingresos1 || 0) + (empleado.otros_ingresos2 || 0)
      
  #     boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
  #     boleta.update!(
  #       sueldo_base_momento: sueldo_periodo.round(2),
  #       dias_trabajados: dias_del_periodo - dias_descuento_completo,
  #       monto_horas_extra: monto_total_horas_extra.round(2), # <--- Guardamos las extras calculadas aquí
  #       otros_ingresos: otros_ing,
  #       isss_retencion: monto_isss,
  #       afp_retencion: monto_afp,
  #       renta_retencion: monto_renta,
  #       descuento_faltas: total_descuentos_asistencia.round(2),
  #       prestamos_internos: 0.0,
  #       total_neto: (sueldo_gravable + otros_ing - monto_isss - monto_afp - monto_renta).round(2)
  #     )
  #   end
  
  #   update!(procesada: true)
  # end

  # def generar_planilla!
  #   return false if procesada
    
  #   config = ConfiguracionPlanilla.actual
    
  #   Empleado.where(status: 'Activo').each do |empleado|
  #     sueldo_periodo = calcular_sueldo_base_periodo(empleado)
      
  #     # Base comercial quincenal/mensual fija en El Salvador
  #     dias_base_calculo = tipo_periodo == 'Quincenal' ? 15.0 : 30.0
  #     valor_dia = sueldo_periodo / dias_base_calculo
  #     valor_hora = valor_dia / config.horas_laborales_dia
  #     valor_minuto = valor_hora / 60.0
  
  #     dias_del_periodo = (fecha_hasta - fecha_desde).to_i + 1
  
  #     rango_fechas = fecha_desde.beginning_of_day..fecha_hasta.end_of_day
  #     asistencias = empleado.asistencias.where(fecha: rango_fechas)
  
  #     # REGLA: Si no hay absolutamente ningún registro de asistencia en el periodo,
  #     # se genera la boleta en cero para todos los contadores de asistencia y cálculos.
  #     if asistencias.empty?
  #       boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
  #       boleta.update!(
  #         sueldo_base_momento: sueldo_periodo.round(2),
  #         dias_trabajados: dias_del_periodo,
  #         monto_horas_extra: 0.0,
  #         otros_ingresos: (empleado.otros_ingresos1 || 0) + (empleado.otros_ingresos2 || 0),
  #         isss_retencion: ([sueldo_periodo, tipo_periodo == 'Quincenal' ? (config.isss_techo_salarial / 2.0) : config.isss_techo_salarial].min * config.isss_porcentaje_empleado).round(2),
  #         afp_retencion: ([sueldo_periodo, tipo_periodo == 'Quincenal' ? (config.afp_techo_salarial / 2.0) : config.afp_techo_salarial].min * config.afp_porcentaje_empleado).round(2),
  #         renta_retencion: 0.0, # Requiere cálculo dinámico según corresponda
  #         descuento_faltas: 0.0,
  #         descuento_retrasos: 0.0,
  #         prestamos_internos: 0.0,
  #         total_neto: sueldo_periodo.round(2)
  #       )
  #       next # Salta al siguiente empleado sin ejecutar cálculos de asistencia
  #     end
  
  #     # Contadores y acumuladores analíticos
  #     dias_descuento_completo = 0
  #     total_minutos_tarde_periodo = 0
  #     monto_total_horas_extra = 0.0
      
  #     fechas_con_registro = asistencias.map { |a| a.fecha.to_date }
  #     dias_laborales_empleado = empleado.dias_laborales
  
  #     # Evaluación diaria de asistencia
  #     (fecha_desde..fecha_hasta).each do |dia_evaluado|
  #       wday_ajustado = (dia_evaluado.wday == 0) ? 7 : dia_evaluado.wday
  #       es_dia_laboral = dias_laborales_empleado.include?(wday_ajustado)
  
  #       if es_dia_laboral && !fechas_con_registro.include?(dia_evaluado)
  #         dias_descuento_completo += 1
  #         next
  #       end
  
  #       as = asistencias.find { |a| a.fecha.to_date == dia_evaluado }
  #       if as.present?
  #         case as.estado
  #         when 'Falta', 'Permiso Sin Goce'
  #           dias_descuento_completo += 1
  #         when 'Asistió'
  #           if as.hora_entrada.present?
  #             limite_entrada = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 8, 0, 0)
  #             reg_entrada = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, as.hora_entrada.hour, as.hora_entrada.min, 0)
              
  #             if reg_entrada > limite_entrada
  #               total_minutos_tarde_periodo += ((reg_entrada - limite_entrada) / 60).to_i
  #             end
  #           end
  
  #           if as.hora_salida.present?
  #             limite_salida = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 17, 0, 0)
  #             reg_salida = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, as.hora_salida.hour, as.hora_salida.min, 0)
              
  #             if reg_salida < limite_salida
  #               total_minutos_tarde_periodo += ((limite_salida - reg_salida) / 60).to_i
  #             elsif reg_salida > limite_salida
  #               inicio_he = limite_salida
  #               fin_he = reg_salida
  #               limite_nocturno = Time.zone.local(dia_evaluado.year, dia_evaluado.month, dia_evaluado.day, 19, 0, 0)
                
  #               horas_extra_diurnas = 0.0
  #               horas_extra_nocturnas = 0.0
                
  #               if fin_he <= limite_nocturno
  #                 horas_extra_diurnas = (fin_he - inicio_he) / 3600.0
  #               else
  #                 horas_extra_diurnas = (limite_nocturno - inicio_he) / 3600.0
  #                 horas_extra_nocturnas = (fin_he - limite_nocturno) / 3600.0
  #               end
                
  #               monto_total_horas_extra += (horas_extra_diurnas * valor_hora * 2.0)
  #               monto_total_horas_extra += (horas_extra_nocturnas * valor_hora * 2.0 * 1.25)
  #             end
  #           end
  #         end
  #       end
  #     end
  
  #     # Evaluación de la regla de minutos de gracia
  #     minutos_a_descontar = total_minutos_tarde_periodo > config.minutos_gracia_periodo ? total_minutos_tarde_periodo : 0
  
  #     # SEPARACIÓN DE DESCUENTOS MONETARIOS (Evita saltos de centavos en redondeos distributivos)
  #     monto_descuento_faltas = (dias_descuento_completo * valor_dia).round(2)
  #     monto_descuento_retrasos = (minutos_a_descontar * valor_minuto).round(2)
      
  #     # Base Gravable Total para Retenciones de Ley
  #     sueldo_gravable = [sueldo_periodo - monto_descuento_faltas - monto_descuento_retrasos + monto_total_horas_extra, 0].max
  
  #     # Descuentos de Ley de El Salvador con control estricto de Techos
  #     techo_isss = tipo_periodo == 'Quincenal' ? (config.isss_techo_salarial / 2.0) : config.isss_techo_salarial
  #     monto_isss = ([sueldo_gravable, techo_isss].min * config.isss_porcentaje_empleado).round(2)
  
  #     techo_afp = tipo_periodo == 'Quincenal' ? (config.afp_techo_salarial / 2.0) : config.afp_techo_salarial
  #     monto_afp = ([sueldo_gravable, techo_afp].min * config.afp_porcentaje_empleado).round(2)
  
  #     base_renta = [sueldo_gravable - monto_isss - monto_afp, 0].max
  #     monto_renta = calcular_renta_sv(base_renta, config).round(2)
  
  #     otros_ing = (empleado.otros_ingresos1 || 0) + (empleado.otros_ingresos2 || 0)
      
  #     # 7. Persistencia de Datos en el Modelo de Boleta
  #     boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
  #     boleta.update!(
  #       sueldo_base_momento: sueldo_periodo.round(2),
  #       dias_trabajados: [dias_del_periodo - dias_descuento_completo, 0].max,
  #       monto_horas_extra: monto_total_horas_extra.round(2),
  #       otros_ingresos: otros_ing,
  #       isss_retencion: monto_isss,
  #       afp_retencion: monto_afp,
  #       renta_retencion: monto_renta,
  #       descuento_faltas: monto_descuento_faltas,     # <--- SOLO FALTAS COMPLETAS
  #       descuento_retrasos: monto_descuento_retrasos, # <--- SE GUARDA APARTE (NUEVO CAMPO)
  #       prestamos_internos: 0.0,
  #       total_neto: (sueldo_gravable + otros_ing - monto_isss - monto_afp - monto_renta).round(2)
  #     )
  #   end
  
  #   update!(procesada: true)
  # end

  def generar_planilla!
    return false if procesada
    
    config = ConfiguracionPlanilla.actual
    
    Empleado.where(status: 'Activo').each do |empleado|
      sueldo_periodo = calcular_sueldo_base_periodo(empleado)
      
      # Base comercial quincenal/mensual fija en El Salvador
      dias_base_calculo = tipo_periodo == 'Quincenal' ? 15.0 : 30.0
      valor_dia = sueldo_periodo / dias_base_calculo
      valor_hora = valor_dia / config.horas_laborales_dia
      valor_minuto = valor_hora / 60.0
  
      dias_del_periodo = (fecha_hasta - fecha_desde).to_i + 1
  
      rango_fechas = fecha_desde.beginning_of_day..fecha_hasta.end_of_day
      asistencias = empleado.asistencias.where(fecha: rango_fechas)
  
      # -------------------------------------------------------------------------
      # EXTRACTOR DE MOVIMIENTOS MANUALES DEL PERIODO (NUEVO)
      # -------------------------------------------------------------------------
      movimientos_periodo = empleado.movimientos_planilla.where(
        fecha: fecha_desde..fecha_hasta,
        procesado: false
      )
  
      total_bonos              = movimientos_periodo.where(tipo: 'Bono').sum(:monto) || 0.0
      total_comisiones         = movimientos_periodo.where(tipo: 'Comision').sum(:monto) || 0.0
      total_viaticos           = movimientos_periodo.where(tipo: 'Viatico').sum(:monto) || 0.0
      total_descuentos_manuales = movimientos_periodo.where(tipo: 'Descuento').sum(:monto) || 0.0
      # -------------------------------------------------------------------------
  
      # REGLA: Si no hay asistencias en el periodo seleccionado, genera el registro en cero cálculos de asistencia.
      if asistencias.empty?
        # Integración en base vacía: se incluyen bonos y comisiones en el cálculo impositivo si existiesen
        sueldo_gravable_vacio = [sueldo_periodo + total_bonos + total_comisiones, 0].max
  
        techo_isss_vacio = tipo_periodo == 'Quincenal' ? (config.isss_techo_salarial / 2.0) : config.isss_techo_salarial
        monto_isss_vacio = ([sueldo_gravable_vacio, techo_isss_vacio].min * config.isss_porcentaje_empleado).round(2)
  
        techo_afp_vacio = tipo_periodo == 'Quincenal' ? (config.afp_techo_salarial / 2.0) : config.afp_techo_salarial
        monto_afp_vacio = ([sueldo_gravable_vacio, techo_afp_vacio].min * config.afp_porcentaje_empleado).round(2)
  
        base_renta_vacia = [sueldo_gravable_vacio - monto_isss_vacio - monto_afp_vacio, 0].max
        monto_renta_vacio = calcular_renta_sv(base_renta_vacia, config).round(2)
  
        # Los viáticos se consolidan en otros ingresos sin pagar impuestos
        otros_ing_vacio = (empleado.otros_ingresos1 || 0) + (empleado.otros_ingresos2 || 0) + total_viaticos
  
        boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
        boleta.update!(
          sueldo_base_momento: sueldo_periodo.round(2),
          dias_trabajados: dias_del_periodo,
          monto_horas_extra: (total_bonos + total_comisiones).round(2), # Muestra el acumulado de incentivos manuales
          otros_ingresos: otros_ing_vacio,
          isss_retencion: monto_isss_vacio,
          afp_retencion: monto_afp_vacio,
          renta_retencion: monto_renta_vacio,
          descuento_faltas: total_descuentos_manuales, # Se le cobra el descuento manual si posee
          descuento_retrasos: 0.0,
          prestamos_internos: 0.0,
          total_neto: (sueldo_gravable_vacio + otros_ing_vacio - monto_isss_vacio - monto_afp_vacio - monto_renta_vacio - total_descuentos_manuales).round(2)
        )
  
        # Marcar movimientos como procesados antes de saltar
        movimientos_periodo.update_all(procesado: true, planilla_id: self.id)
        next 
      end
  
      # Contadores analíticos individuales
      dias_descuento_completo = 0
      total_minutos_tarde_periodo = 0
      monto_total_horas_extra = 0.0
      
      fechas_con_registro = asistencias.map { |a| a.fecha.to_date }
      dias_laborales_empleado = empleado.dias_laborales
  
      # Procesamiento diario de marcaciones
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
  
      # Minutos de gracia acumulados en el periodo seleccionado
      minutos_a_descontar = total_minutos_tarde_periodo > config.minutos_gracia_periodo ? total_minutos_tarde_periodo : 0
  
      # Cálculo individual de montos por descuento de asistencia
      monto_descuento_faltas = (dias_descuento_completo * valor_dia).round(2)
      monto_descuento_retrasos = (minutos_a_descontar * valor_minuto).round(2)
      
      # =========================================================================
      # INTEGRACIÓN DE INGRESOS MANUALES GRAVABLES (BONOS Y COMISIONES)
      # Se incorporan a la base imponible para el cálculo correcto de deducciones.
      # =========================================================================
      ingresos_adicionales_imponibles = monto_total_horas_extra + total_bonos + total_comisiones
      sueldo_gravable = [sueldo_periodo - monto_descuento_faltas - monto_descuento_retrasos + ingresos_adicionales_imponibles, 0].max
  
      # Retenciones calculadas sobre la base gravable limpia individual
      techo_isss = tipo_periodo == 'Quincenal' ? (config.isss_techo_salarial / 2.0) : config.isss_techo_salarial
      monto_isss = ([sueldo_gravable, techo_isss].min * config.isss_porcentaje_empleado).round(2)
  
      techo_afp = tipo_periodo == 'Quincenal' ? (config.afp_techo_salarial / 2.0) : config.afp_techo_salarial
      monto_afp = ([sueldo_gravable, techo_afp].min * config.afp_porcentaje_empleado).round(2)
  
      # Base de Renta exacta calculada dinámicamente
      base_renta = [sueldo_gravable - monto_isss - monto_afp, 0].max
      monto_renta = calcular_renta_sv(base_renta, config).round(2)
  
      # Consolidación de ingresos exentos (Fijos de la ficha + Viáticos manuales del periodo)
      otros_ing = (empleado.otros_ingresos1 || 0) + (empleado.otros_ingresos2 || 0) + total_viaticos
      
      # Consolidación total de egresos (Descuentos de asistencia + Descuentos manuales de la vista)
      descuentos_totales_faltas = monto_descuento_faltas + total_descuentos_manuales
  
      # Almacenamiento unificado en la Boleta de Pago
      boleta = boletas_de_pago.find_or_initialize_by(empleado: empleado)
      boleta.update!(
        sueldo_base_momento: sueldo_periodo.round(2),
        dias_trabajados: [dias_del_periodo - dias_descuento_completo, 0].max,
        monto_horas_extra: ingresos_adicionales_imponibles.round(2), # Refleja horas extra + bonos + comisiones
        otros_ingresos: otros_ing.round(2),
        isss_retencion: monto_isss,                      
        afp_retencion: monto_afp,                        
        renta_retencion: monto_renta,                    
        descuento_faltas: descuentos_totales_faltas.round(2),
        descuento_retrasos: monto_descuento_retrasos,     
        prestamos_internos: 0.0,
        # El Neto final resta de forma transparente el dinero de los descuentos manuales
        total_neto: (sueldo_gravable + otros_ing - monto_isss - monto_afp - monto_renta - total_descuentos_manuales).round(2)
      )
  
      # Cambiar estado a los movimientos para evitar duplicación de cobro en futuros cierres
      movimientos_periodo.update_all(procesado: true, planilla_id: self.id)
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