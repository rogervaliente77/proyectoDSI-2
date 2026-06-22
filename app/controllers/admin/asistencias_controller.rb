# app/controllers/admin/asistencias_controller.rb
module Admin
  class AsistenciasController < Admin::ApplicationController
    before_action :set_current_user
    before_action :set_fecha, only: [:index, :registrar]
    before_action :validar_dia_laboral, only: [:index, :registrar]
    layout 'dashboard'

    def index
      @empleados = Empleado.where(status: 'Activo')
      @asistencias_hoy = Asistencia.where(fecha: @fecha).index_by(&:empleado_id)
    end

    def registrar
      @empleado = Empleado.find(params[:empleado_id])
      @asistencia = Asistencia.find_or_initialize_by(empleado: @empleado, fecha: @fecha)

      # Asignación manual de horas si vienen en los params
      if params[:hora_entrada].present?
        @asistencia.hora_entrada = Time.zone.parse("#{@fecha} #{params[:hora_entrada]}")
      end
      if params[:hora_salida].present?
        @asistencia.hora_salida = Time.zone.parse("#{@fecha} #{params[:hora_salida]}")
      end

      @asistencia.estado = params[:estado]
      @asistencia.justificacion = params[:justificacion]
      @asistencia.es_parcial = params[:es_parcial] == "true"

      if @asistencia.save
        redirect_to admin_asistencias_path(fecha: @fecha), notice: "Registro actualizado."
      else
        redirect_to admin_asistencias_path(fecha: @fecha), alert: "Error al guardar."
      end
    end
    
    # app/controllers/admin/asistencias_controller.rb
    def reporte_cortes
      @empleados = Empleado.where(status: 'Activo')
      
      # Definimos el periodo actual para mostrar datos frescos
      hoy = Date.today
      @inicio_periodo = hoy.day <= 15 ? hoy.change(day: 1) : hoy.change(day: 16)
      @fin_periodo = hoy.day <= 15 ? hoy.change(day: 15) : hoy.end_of_month
      
      # Opcional: Podrías calcular el porcentaje "en vivo" para la vista
      @reporte = @empleados.map do |emp|
        dias_laborales = (@inicio_periodo..hoy).count { |d| (1..5).include?(d.wday) }
        faltas = Asistencia.where(empleado: emp, fecha: @inicio_periodo..hoy, estado: 'Falta Injustificada').count
        
        {
          empleado: emp,
          porcentaje: dias_laborales > 0 ? ((dias_laborales - faltas).to_f / dias_laborales) : 1.0,
          faltas_count: faltas
        }
      end
    end

    # Acción para procesar el corte del 10 o 25
    def procesar_corte
      fecha_corte = params[:fecha_corte].to_date
      # Definir rango: si es 25, del 11 al 25. Si es 10, del 26 al 10.
      inicio = fecha_corte.day == 25 ? fecha_corte.change(day: 11) : (fecha_corte - 1.month).change(day: 26)
      
      @empleados = Empleado.where(status: 'Activo')
      
      @empleados.each do |emp|
        # Días laborables (Lunes a Viernes)
        dias_laborables = (inicio..fecha_corte).count { |d| (1..5).include?(d.wday) }
        
        # Asistencias que cuentan para sueldo
        asistencias_validas = Asistencia.where(empleado: emp, fecha: inicio..fecha_corte).select(&:dia_pagado?).count
        
        porcentaje = dias_laborables > 0 ? (asistencias_validas.to_f / dias_laborables) : 0
        emp.update(porcentaje_pago_actual: porcentaje.round(4))
      end

      redirect_to admin_asistencias_path, notice: "Corte procesado para #{fecha_corte}. Porcentajes actualizados."
    end

    private

    def set_fecha
      @fecha = params[:fecha].present? ? params[:fecha].to_date : Date.today
    end

    def set_current_user
      @current_user = current_user
    end

    private

    def validar_dia_laboral
      # 1. Capturamos la fecha del parámetro o la de hoy
      @fecha = params[:fecha].present? ? params[:fecha].to_date : Date.today

      # 2. Si es fin de semana, buscamos el lunes más cercano para evitar el bucle
      if @fecha.saturday? || @fecha.sunday?
        proximo_lunes = @fecha.next_week(:monday)
        
        # Solo redirigimos si la fecha en la URL es distinta al próximo lunes
        # para romper el bucle infinito
        if params[:fecha] != proximo_lunes.to_s
          flash[:alert] = "Los fines de semana no son días laborales. Mostrando próximo lunes: #{proximo_lunes.strftime('%d/%m/%Y')}"
          redirect_to admin_asistencias_path(fecha: proximo_lunes)
        end
      end
    end
  
  end
end