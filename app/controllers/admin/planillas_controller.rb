module Admin
  class PlanillasController < Admin::ApplicationController
    layout 'dashboard'

    def index
      # Por defecto, si no viene parámetro, muestra las ordinarias
      @tipo_actual = params[:tipo] || 'Salarial Ordinaria'
      
      # Filtramos las planillas según la pestaña activa
      @planillas = Planilla.where(tipo_planilla: @tipo_actual).order_by(created_at: :desc)
    end

    def new
      # Con esto garantizamos que la instancia de @planilla nazca con el tipo correcto
      @planilla = Planilla.new(
        tipo_planilla: params[:tipo] || 'Salarial Ordinaria', 
        fecha_desde: Date.today.beginning_of_month, 
        fecha_hasta: Date.today
      )
      @tipo_actual = params[:tipo_periodo] || 'Quincenal'
      @periodos_disponibles = generar_periodos_disponibles(@tipo_actual)
    end

    # def create
    #   # Recuperamos el rango automático empaquetado en el selector de periodos
    #   rango_seleccionado = params[:planilla][:periodo_automatico]
      
    #   if rango_seleccionado.present?
    #     desde_str, hasta_str = rango_seleccionado.split(" al ")
    #     fecha_desde = Date.parse(desde_str)
    #     fecha_hasta = Date.parse(hasta_str)
    #   end

    #   @planilla = Planilla.new(planilla_params)
    #   @planilla.fecha_desde = fecha_desde
    #   @planilla.fecha_hasta = fecha_hasta
    #   @planilla.nombre = "Planilla #{@planilla.tipo_periodo} (#{fecha_desde.strftime('%d/%m')} al #{fecha_hasta.strftime('%d/%m/%Y')})"

    #   if @planilla.save
    #     @planilla.generar_planilla!
    #     redirect_to admin_planillas_path, notice: "Planilla calculada exitosamente basándose en la asistencia real."
    #   else
    #     @tipo_actual = @planilla.tipo_periodo || 'Quincenal'
    #     @periodos_disponibles = generar_periodos_disponibles(@tipo_actual)
    #     flash.now[:alert] = @planilla.errors.full_messages.to_sentence
    #     render :new, status: :unprocessable_entity
    #   end
    # end

    def create
      # Instanciamos la planilla primero para saber qué tipo es
      @planilla = Planilla.new(planilla_params)
    
      if @planilla.tipo_planilla == "Aguinaldo"
        # =========================================================================
        # FLUJO INDEPENDIENTE PARA AGUINALDOS (No toca tu lógica ordinaria)
        # =========================================================================
        ano_actual = Time.now.year
        @planilla.tipo_periodo = "Mensual"
        @planilla.fecha_desde  = Date.new(ano_actual, 1, 1)   # 01/01/2026
        @planilla.fecha_hasta  = Date.new(ano_actual, 12, 12) # 12/12/2026 (Corte de Ley)
        
        # Mantiene el nombre que el usuario escribió en el input de la vista
        @planilla.nombre = "#{@planilla.nombre} (#{ano_actual})" if @planilla.nombre.present?
    
      else
        # =========================================================================
        # TU LÓGICA ORIGINAL INTACTA (Para Ordinarias y Quincena 25)
        # =========================================================================
        rango_seleccionado = params[:planilla][:periodo_automatico]
        
        if rango_seleccionado.present?
          desde_str, hasta_str = rango_seleccionado.split(" al ")
          fecha_desde = Date.parse(desde_str)
          fecha_hasta = Date.parse(hasta_str)
        end
    
        @planilla.fecha_desde = fecha_desde
        @planilla.fecha_hasta = fecha_hasta
        @planilla.nombre = "Planilla #{@planilla.tipo_periodo} (#{fecha_desde.strftime('%d/%m')} al #{fecha_hasta.strftime('%d/%m/%Y')})"
      end
    
      # =========================================================================
      # GUARDADO Y REDIRECCIÓN (Adaptado para volver a la pestaña correcta)
      # =========================================================================
      if @planilla.save
        @planilla.generar_planilla!
        # Redirige especificando el tipo para que el usuario caiga en la pestaña correspondiente
        redirect_to admin_planillas_path(tipo: @planilla.tipo_planilla), notice: "Planilla calculada exitosamente basándose en la asistencia real."
      else
        # Tu lógica original de errores en caso de fallo
        @tipo_actual = @planilla.tipo_periodo || 'Quincenal'
        @periodos_disponibles = generar_periodos_disponibles(@tipo_actual) if defined?(generar_periodos_disponibles)
        flash.now[:alert] = @planilla.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @planilla = Planilla.find(params[:id])
      @boletas = @planilla.boletas_de_pago.includes(:empleado)
    end

    def destroy
      @planilla = Planilla.find(params[:id])
      tipo = @planilla.tipo_planilla # o el nombre exacto de tu campo de tipo
      
      if @planilla.destroy
        flash[:success] = "Planilla y boletas de pago eliminadas correctamente."
      else
        flash[:error] = "No se pudo eliminar la planilla."
      end
      
      redirect_to admin_planillas_path(tipo: tipo)
    end

    private

    def planilla_params
      # CORRECCIÓN: Asegúrate de que :nombre sea el primer parámetro permitido
      params.require(:planilla).permit(:nombre, :tipo_periodo, :tipo_planilla, :fecha_desde, :fecha_hasta, :fecha_pago)
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