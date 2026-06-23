module Admin
  class AsistenciasController < Admin::ApplicationController
    layout 'dashboard'

    def index
      @empleado = Empleado.find(params[:empleado_id])
      
      # --- Configuración de la vista Semanal ---
      @fecha_base = params[:fecha] ? Date.parse(params[:fecha]) : Date.today
      @inicio_semana = @fecha_base.beginning_of_week(:monday)
      @fin_semana = @fecha_base.end_of_week(:monday)
      @dias_semana = (@inicio_semana..@fin_semana).to_a
    
      # --- Configuración de la vista Calendario Mensual ---
      @mes_base = params[:mes] ? Date.parse(params[:mes]) : Date.today.beginning_of_month
      @inicio_mes_calendario = @mes_base.beginning_of_month.beginning_of_week(:monday)
      @fin_mes_calendario = @mes_base.end_of_month.end_of_week(:monday)
      @todas_semanas_mes = (@inicio_mes_calendario..@fin_mes_calendario).to_a.each_slice(7).to_a
    
      # Traer TODO el historial de asistencia del mes para pintar el calendario
      asistencias_mes = @empleado.asistencias.where(:fecha.gte => @inicio_mes_calendario, :fecha.lte => @fin_mes_calendario)
      @asistencias_mes_hash = asistencias_mes.index_by(&:fecha)
      
      # Combinar asistencias semanales
      asistencias_docs = @empleado.asistencias.where(:fecha.in => @dias_semana)
      @asistencias_hash = asistencias_docs.index_by(&:fecha)
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
            asistencia.hora_entrada = nil
          end
    
          if datos[:hora_salida].present?
            asistencia.hora_salida = Time.zone.parse("#{fecha_str} #{datos[:hora_salida]}")
          else
            asistencia.hora_salida = nil
          end
        else
          # Si es Falta, Permiso, Vacación o Incapacidad, se limpian las horas de entrada/salida
          asistencia.hora_entrada = nil
          asistencia.hora_salida = nil
        end
    
        # 4. Guardar el documento en MongoDB
        asistencia.save
      end
    
      # Redirección manteniendo la fecha base de la semana y forzando que se quede en la pestaña 'semana'
      redirect_to admin_empleado_asistencias_path(@empleado, fecha: params[:fecha_base], vista: 'semana'), 
                  notice: "Asistencias actualizadas correctamente."
    end

  end
end