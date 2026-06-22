# app/controllers/admin/asistencias_controller.rb
module Admin
  class PlanillasController < Admin::ApplicationController
    before_action :set_current_user
    layout 'dashboard'

    def index
      @planillas = Planilla.all.order(created_at: :desc)
    end
  
    def new
      @planilla = Planilla.new
    end
  
    def create
      @planilla = Planilla.new(planilla_params)
      if @planilla.save
        generar_boletas_masivas(@planilla)
        redirect_to admin_planilla_path(@planilla), notice: "Planilla y Boletas generadas exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end
  
    def show
      @planilla = Planilla.find(params[:id])
      @boletas = @planilla.boletas_de_pago.includes(:empleado)
    end
  
    private
  
    def planilla_params
      params.require(:planilla).permit(:nombre, :tipo_periodo, :fecha_desde, :fecha_hasta, :fecha_pago)
    end

    def set_current_user
      @current_user = current_user
    end
  
    def generar_boletas_masivas(planilla)
      Empleado.where(status: 'Activo').each do |emp|
        # 1. Sueldo base quincenal (usando el porcentaje de asistencia que calculamos antes)
        sueldo_bruto = emp.salario_quincenal * (emp.porcentaje_pago_actual || 1.0)
        
        # 2. Descuentos Pre-Renta
        isss = CalculadoraSvService.calcular_isss(sueldo_bruto)
        afp = CalculadoraSvService.calcular_afp(sueldo_bruto)
        
        # 3. Cálculo de Renta (Base gravable = Bruto - ISSS - AFP)
        base_renta = sueldo_bruto - isss - afp
        renta = CalculadoraSvService.calcular_renta(base_renta, :quincenal)
        
        # 4. Total Líquido
        liquido = sueldo_bruto - isss - afp - renta
  
        planilla.boletas_de_pago.create!(
          empleado: emp,
          sueldo_base_momento: emp.salario_mensual,
          isss_retencion: isss,
          afp_retencion: afp,
          renta_retencion: renta,
          total_neto: liquido
        )
      end
    end
  
  end
end
