module Admin
  class EmpleadosController < Admin::ApplicationController
    before_action :set_current_user
    # before_action :check_admin_access
    # before_action :set_product, only: %i[ product_sales edit update destroy]
    layout 'dashboard'
    
    def index
      # binding.pry
      @empleados = Empleado.all
    end

    def new
      @empleado = Empleado.new
    end

    def create
      @empleado = Empleado.new(empleado_params)
  
      if @empleado.save
        redirect_to admin_empleados_path, notice: "Empleado creado exitosamente."
      else
        flash.now[:alert] = "Error al crear el empleado: #{@empleado.errors.full_messages.to_sentence}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @empleado = Empleado.find(params[:id])
    end
    
    def update
      @empleado = Empleado.find(params[:id])
      if @empleado.update(empleado_params)
        redirect_to admin_empleados_path, notice: "Información actualizada correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # app/controllers/admin/empleados_controller.rb
    def show
      @empleado = Empleado.find(params[:id])
    end

    def destroy
      @empleado = Empleado.find(params[:id])
      if @empleado.destroy
        redirect_to admin_empleados_path, notice: "Empleado eliminado correctamente."
      else
        redirect_to admin_empleados_path, alert: "No se pudo eliminar el empleado."
      end
    end

    private
  
    # Strong Parameters: Permite solo los campos definidos en tu modelo
    def empleado_params
      params.require(:empleado).permit(
        :first_name, 
        :last_name, 
        :full_name, 
        :email, 
        :phone_number, 
        :address, 
        :cargo_name, 
        :nit, 
        :dui, 
        :fecha_inicio_trabajo, 
        :fecha_nacimiento, 
        :status, 
        :banco_medio_pago, 
        :cuenta_bancaria, 
        :grado_academico, 
        :nivel_educacion, 
        :salario_mensual, 
        :salario_quincenal,
        :otros_ingresos1,
        :otros_ingresos2,
        :otros_ingresos3,
        :detalle_otros_ingresos1
      )
    end

    def set_current_user
      @current_user = current_user
    end

    def client_params
      params.require(:client).permit(:first_name, :last_name, :full_name, :email, :phone_number, :address,
                                   :giro, :nit, :dui, :tipo_cliente)
    end

    def next_codigo(prefijo)
      # Busca el último documento cuyo codigo empiece por "CN-" o "CJ-"
      regex = /^#{Regexp.escape(prefijo)}-/
      ultimo = Client.where(code: regex).order_by(code: :desc).limit(1).pluck(:code).first

      if ultimo.present?
        numero = ultimo.split("-").last.to_i + 1
      else
        numero = 1
      end

      numero_formateado = numero.to_s.rjust(7, "0")
      "#{prefijo}-#{numero_formateado}"
    end

  end
end
