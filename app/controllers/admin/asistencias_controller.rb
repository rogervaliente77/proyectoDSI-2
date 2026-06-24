module Admin
  class AsistenciasController < Admin::ApplicationController
    layout 'dashboard'

    def index
      @empleado = Empleado.find(params[:empleado_id])
    
      # =========================================================================
      # 1. LÓGICA ANTERIOR: CONTROL SEMANAL (EDITAR)
      # =========================================================================
      @fecha_base = params[:fecha].present? ? Date.parse(params[:fecha]) : Date.today
      @inicio_semana = @fecha_base.beginning_of_week(:monday)
      @fin_semana = @fecha_base.end_of_week(:monday)
      @dias_semana = (@inicio_semana..@fin_semana).to_a
    
      # Mapear asistencias semanales en un Hash para rendimiento óptimo
      asistencias_semana = @empleado.asistencias.where(fecha: @inicio_semana.beginning_of_day..@fin_semana.end_of_day)
      @asistencias_hash = asistencias_semana.each_with_object({}) do |asistencia, hash|
        hash[asistencia.fecha.to_date] = asistencia
      end
    
    
      # =========================================================================
      # 2. LÓGICA ANTERIOR: VISTA CALENDARIO MENSUAL
      # =========================================================================
      @mes_base = params[:mes].present? ? Date.parse(params[:mes]) : Date.today
      inicio_mes = @mes_base.beginning_of_month
      fin_mes = @mes_base.end_of_month
      
      # Estructurar la cuadrícula completa del calendario (incluyendo días sobrantes de la semana)
      inicio_calendario = inicio_mes.beginning_of_week(:monday)
      fin_calendario = fin_mes.end_of_week(:monday)
      
      # Agrupar el rango de días en sub-arreglos de 7 elementos (semanas)
      @todas_semanas_mes = (inicio_calendario..fin_calendario).to_a.each_slice(7).to_a
    
      # Mapear asistencias mensuales en un Hash
      asistencias_mes = @empleado.asistencias.where(fecha: inicio_calendario.beginning_of_day..fin_calendario.end_of_day)
      @asistencias_mes_hash = asistencias_mes.each_with_object({}) do |asistencia, hash|
        hash[asistencia.fecha.to_date] = asistencia
      end
    
    
      # =========================================================================
      # 3. NUEVA LÓGICA: MÉTRICAS Y PREVIEW DE PLANILLA (RANGOS AUTOMÁTICOS)
      # =========================================================================
      # Definir rango por defecto si el usuario no ha enviado fechas (Últimos 30 días)
      @fecha_inicio_preview = params[:fecha_inicio_preview].present? ? Date.parse(params[:fecha_inicio_preview]) : (Date.today - 30.days)
      @fecha_fin_preview = params[:fecha_fin_preview].present? ? Date.parse(params[:fecha_fin_preview]) : Date.today
    
      # Buscar asistencias acumuladas en el rango del Preview
      asistencias_preview = @empleado.asistencias.where(fecha: @fecha_inicio_preview.beginning_of_day..@fecha_fin_preview.end_of_day)
    
      # Recuperar reglas configuradas (Días laborales del empleado y minutos de gracia)
      dias_laborales_emp = @empleado.dias_laborales
      config = ConfiguracionPlanilla.actual
      @limite_gracia = config.minutos_gracia_periodo
    
      # Inicialización de contadores analíticos
      @dias_que_debio_asistir = 0
      @asistencias_efectivas = 0
      @faltas_detectadas = 0
      @permisos_vacaciones = 0
      @minutos_tarde_entrada = 0
      @minutos_salida_temprana = 0
    
      # Arrays vacíos que se enviarán serializados a Chart.js en la vista
      @fechas_grafica = []
      @valores_grafica_entrada = []
      @valores_grafica_salida = []
    
      # Bucle evaluador día por día dentro del periodo de consulta
      (@fecha_inicio_preview..@fecha_fin_preview).each do |dia|
        wday_ajustado = (dia.wday == 0) ? 7 : dia.wday
        
        # Si el día no pertenece a la jornada laboral del empleado, se ignora del análisis
        next unless dias_laborales_emp.include?(wday_ajustado)
    
        @dias_que_debio_asistir += 1
        as = asistencias_preview.find { |a| a.fecha.to_date == dia }
    
        if as.nil?
          # Si debió venir y no existe registro alguno, cuenta como inasistencia directa
          @faltas_detectadas += 1
        else
          case as.estado
          when 'Asistió'
            @asistencias_efectivas += 1
            mins_ent = 0
            mins_sal = 0
    
            # Evaluar entrada retrasada (Límite teórico de las 08:00 AM)
            if as.hora_entrada.present?
              limite_e = Time.zone.local(dia.year, dia.month, dia.day, 8, 0, 0)
              reg_e = Time.zone.local(dia.year, dia.month, dia.day, as.hora_entrada.hour, as.hora_entrada.min, 0)
              
              if reg_e > limite_e
                mins_ent = ((reg_e - limite_e) / 60).to_i
                @minutos_tarde_entrada += mins_ent
              end
            end
    
            # Evaluar salida anticipada (Límite teórico de las 05:00 PM / 17:00)
            if as.hora_salida.present?
              limite_s = Time.zone.local(dia.year, dia.month, dia.day, 17, 0, 0)
              reg_s = Time.zone.local(dia.year, dia.month, dia.day, as.hora_salida.hour, as.hora_salida.min, 0)
              
              if reg_s < limite_s
                mins_sal = ((limite_s - reg_s) / 60).to_i
                @minutos_salida_temprana += mins_sal
              end
            end
    
            # Si el día registró alguna anomalía de tiempo, alimentamos los datos de la gráfica
            if mins_ent > 0 || mins_sal > 0
              @fechas_grafica << dia.strftime("%d/%m")
              @valores_grafica_entrada << mins_ent
              @valores_grafica_salida << mins_sal
            end
    
          when 'Falta', 'Permiso Sin Goce'
            @faltas_detectadas += 1
          when 'Permiso Con Goce', 'Incapacidad', 'Vacación'
            @permisos_vacaciones += 1
            @asistencias_efectivas += 1 # Suma al rendimiento ya que está justificado legalmente
          end
        end
      end
    
      # Cálculo del porcentaje final de asistencia evitando errores de división por cero
      @porcentaje_asistencia = @dias_que_debio_asistir > 0 ? ((@asistencias_efectivas.to_f / @dias_que_debio_asistir) * 100).round(2) : 100.0
      @total_minutos_retraso_periodo = @minutos_tarde_entrada + @minutos_salida_temprana
    end

    

    # Guardar/Actualizar la semana completa vía formulario rápido
    def actualizar_semana
      @empleado = Empleado.find(params[:empleado_id])
      asistencias_params = params[:asistencias] || {}
      hoy = Date.today
    
      asistencias_params.each do |fecha_str, datos|
        fecha = Date.parse(fecha_str)
        
        # 1. VALIDACIÓN BACKEND: No permitir guardar fechas en el futuro
        next if fecha > hoy 
    
        # 2. Buscar el registro del día o inicializar uno nuevo
        asistencia = @empleado.asistencias.find_or_initialize_by(fecha: fecha)
        
        asistencia.estado = datos[:estado]
        asistencia.observaciones = datos[:observaciones]
    
        # 3. Lógica de Horas según el Estado seleccionado
        if datos[:estado] == 'Asistió'
          # Se concatena la fecha del registro con el string de hora enviado por el input time (HH:MM)
          if datos[:hora_entrada].present?
            asistencia.hora_entrada = Time.zone.parse("#{fecha_str} #{datos[:hora_entrada]}")
          else
            next # <--- CAMBIADO: No guarda este día y pasa al siguiente del formulario
          end
    
          if datos[:hora_salida].present?
            asistencia.hora_salida = Time.zone.parse("#{fecha_str} #{datos[:hora_salida]}")
          else
            next # <--- CAMBIADO: No guarda este día y pasa al siguiente del formulario
          end
        else
          # Si es Falta, Permiso, Vacación o Incapacidad, se limpian las horas de entrada/salida
          asistencia.hora_entrada = nil
          asistencia.hora_salida = nil
        end
    
        # 4. Guardar el documento en MongoDB (Solo llegará aquí si no entró a los 'next')
        asistencia.save
    
        # 4. Guardar el documento en MongoDB
        asistencia.save
      end
    
      # Redirección manteniendo la fecha base de la semana y forzando que se quede en la pestaña 'semana'
      redirect_to admin_empleado_asistencias_path(@empleado, fecha: params[:fecha_base], vista: 'semana'), 
                  notice: "Asistencias actualizadas correctamente."
    end

  end
end