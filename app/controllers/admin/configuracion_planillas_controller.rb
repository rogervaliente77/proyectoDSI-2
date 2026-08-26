module Admin
  class ConfiguracionPlanillasController < Admin::ApplicationController
    before_action :set_configuracion
    layout 'dashboard'

    def show
      # Muestra el estado actual de los techos y tablas
    end

    def edit
      # Renderiza el formulario de edición
    end

    def update
      if @configuracion.update(configuracion_params)
        redirect_to admin_configuracion_planilla_path, notice: "Configuración de ley actualizada correctamente."
      else
        flash.now[:alert] = "Error al guardar la configuración: #{@configuracion.errors.full_messages.to_sentence}"
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_configuracion
      @configuracion = ConfiguracionPlanilla.actual
    end

    def configuracion_params
      params.require(:configuracion_planilla).permit(
        :nombre_config, :isss_porcentaje_empleado, :isss_techo_salarial,
        :afp_porcentaje_empleado, :afp_techo_salarial, :minutos_gracia_periodo,
        :horas_laborales_dia, :dia_corte_quincena_1, :dia_corte_quincena_2,
        dias_laborales_defecto: [],
        # NUEVO: Permitir las tablas de renta anidadas con sus respectivas llaves
        tramos_renta_mensual: [:desde, :hasta, :porcentaje, :cuota_fija, :sobre_exceso],
        tramos_renta_quincenal: [:desde, :hasta, :porcentaje, :cuota_fija, :sobre_exceso],
        tramos_renta_semanal: [:desde, :hasta, :porcentaje, :cuota_fija, :sobre_exceso]
      )
    end
  end
end