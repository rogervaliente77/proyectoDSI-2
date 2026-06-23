module Admin
  class PlanillasController < Admin::ApplicationController
    layout 'dashboard'

    def index
      @planillas = Planilla.all.order_by(fecha_desde: :desc)
    end

    def new
      @planilla = Planilla.new
      # Fechas sugeridas basadas en el día actual
      config = ConfiguracionPlanilla.actual
      hoy = Date.today
      
      # Pre-llenar fechas aproximadas según los cortes de El Salvador
      if hoy.day <= config.dia_corte_quincena_1
        @planilla.fecha_desde = (hoy - 1.month).change(day: config.dia_corte_quincena_2 + 1)
        @planilla.fecha_hasta = hoy.change(day: config.dia_corte_quincena_1)
      else
        @planilla.fecha_desde = hoy.change(day: config.dia_corte_quincena_1 + 1)
        @planilla.fecha_hasta = hoy.change(day: config.dia_corte_quincena_2)
      end
    end

    def create
      @planilla = Planilla.new(planilla_params)
      @planilla.nombre = "Planilla #{@planilla.tipo_periodo} (#{@planilla.fecha_desde.strftime('%d/%m')} al #{@planilla.fecha_hasta.strftime('%d/%m/%Y')})"

      if @planilla.save
        @planilla.generar_planilla! # Ejecuta los cálculos del motor automáticamente
        redirect_to admin_planillas_path, notice: "Planilla generada y procesada con éxito."
      else
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
      params.require(:planilla).permit(:tipo_periodo, :fecha_desde, :fecha_hasta, :fecha_pago)
    end
  end
end