module Admin
  class PlanillasController < Admin::ApplicationController
    layout 'dashboard'

    def index
      @planillas = Planilla.all.order_by(fecha_desde: :desc)
    end

    def new 
      @planilla = Planilla.new
      @tipo_actual = params[:tipo_periodo] || 'Quincenal'
      @periodos_disponibles = generar_periodos_disponibles(@tipo_actual)
    end

    def create
      # Recuperamos el rango automático empaquetado en el selector de periodos
      rango_seleccionado = params[:planilla][:periodo_automatico]
      
      if rango_seleccionado.present?
        desde_str, hasta_str = rango_seleccionado.split(" al ")
        fecha_desde = Date.parse(desde_str)
        fecha_hasta = Date.parse(hasta_str)
      end

      @planilla = Planilla.new(planilla_params)
      @planilla.fecha_desde = fecha_desde
      @planilla.fecha_hasta = fecha_hasta
      @planilla.nombre = "Planilla #{@planilla.tipo_periodo} (#{fecha_desde.strftime('%d/%m')} al #{fecha_hasta.strftime('%d/%m/%Y')})"

      if @planilla.save
        @planilla.generar_planilla!
        redirect_to admin_planillas_path, notice: "Planilla calculada exitosamente basándose en la asistencia real."
      else
        @tipo_actual = @planilla.tipo_periodo || 'Quincenal'
        @periodos_disponibles = generar_periodos_disponibles(@tipo_actual)
        flash.now[:alert] = @planilla.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @planilla = Planilla.find(params[:id])
      @boletas = @planilla.boletas_de_pago.includes(:empleado)
    end

    private

    def planilla_params
      params.require(:planilla).permit(:tipo_periodo, :fecha_pago)
    end

    # Método mágico para calcular los periodos exactos hacia atrás
    def generar_periodos_disponibles(tipo)
      periodos = []
      hoy = Date.today

      case tipo
      when 'Semanal'
        # Generar bloques de 10 en 10 días para los últimos 3 meses
        referencia = hoy
        12.times do
          mes = referencia.month
          anio = referencia.year
          
          # Bloque 3: del 21 al fin de mes
          fin_mes = referencia.end_of_month.day
          periodos << ["Del 21 al #{fin_mes} de #{l(referencia, format: '%B %Y')}", "21/#{mes}/#{anio} al #{fin_mes}/#{mes}/#{anio}"]
          # Bloque 2: del 11 al 20
          periodos << ["Del 11 al 20 de #{l(referencia, format: '%B %Y')}", "11/#{mes}/#{anio} al 20/#{mes}/#{anio}"]
          # Bloque 1: del 01 al 10
          periodos << ["Del 01 al 10 de #{l(referencia, format: '%B %Y')}", "01/#{mes}/#{anio} al 10/#{mes}/#{anio}"]
          
          referencia = referencia - 1.month
        end

      when 'Quincenal'
        # Quincenas estipuladas: del 11 al 25 y del 26 al 10 del siguiente mes
        referencia = hoy
        8.times do
          mes_actual = referencia.month
          anio_actual = referencia.year
          
          # Quincena B: Del 11 al 25 de este mes
          periodos << ["Del 11 al 25 de #{l(referencia, format: '%B %Y')}", "11/#{mes_actual}/#{anio_actual} al 25/#{mes_actual}/#{anio_actual}"]
          
          # Quincena A: Del 26 del mes anterior al 10 de este mes
          mes_anterior_ref = referencia - 1.month
          periodos << ["Del 26 de #{l(mes_anterior_ref, format: '%B')} al 10 de #{l(referencia, format: '%B %Y')}", "26/#{mes_anterior_ref.month}/#{mes_anterior_ref.year} al 10/#{mes_actual}/#{anio_actual}"]
          
          referencia = referencia - 1.month
        end

      when 'Mensual'
        # Meses completos estándar
        referencia = hoy
        6.times do
          ini = referencia.beginning_of_month
          fin = referencia.end_of_month
          periodos << ["Mes completo de #{l(referencia, format: '%B %Y')}", "#{ini.strftime('%d/%m/%Y')} al #{fin.strftime('%d/%m/%Y')}"]
          referencia = referencia - 1.month
        end
      end
      
      periodos
    end
  end
end