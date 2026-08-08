module Admin
  class ServiceOrdersController < Admin::ApplicationController
    before_action :set_client_car, only: [:new, :create]
    before_action :set_service_order, only: [:show, :edit, :update, :destroy, :print_pdf]
    layout 'dashboard'

    def index
      @service_orders = ServiceOrder.includes(client_car: :client).order(created_at: :desc)

      if params[:client_id].present?
        @client = Client.find_by(id: params[:client_id])
        
        if @client
          # Obtenemos las órdenes asociadas a los carros del cliente
          car_ids = @client.client_cars.pluck(:id)
          @service_orders = @service_orders.where(:client_car_id.in => car_ids)
        end
      end
    end

    def show; end

    def new
      @service_order = @client_car.service_orders.build
      
      # Precalcula el número y código para mostrarlos inmediatamente en la vista
      @service_order.preparar_correlativos
    
      # Construimos al menos un servicio y un ítem por defecto para el formulario
      @service_order.order_services.build
      @service_order.order_items.build
    end

    def create
      @service_order = @client_car.service_orders.build(service_order_params)
      
      # Recalcular totales antes de guardar
      calcular_totales(@service_order)

      if @service_order.save
        redirect_to admin_service_order_path(@service_order), notice: 'Orden de servicio creada con éxito.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @client_car = @service_order.client_car
    end

    def print_pdf
      pdf = GenerateMantenimientoServicePdf.new(@service_order)
    
      respond_to do |format|
        format.pdf do
          send_data pdf.render,
                    filename: "Orden_#{@service_order.numero_orden}_BIMERS.pdf",
                    type: 'application/pdf',
                    disposition: 'inline'
        end
        format.all do
          send_data pdf.render,
                    filename: "Orden_#{@service_order.numero_orden}_BIMERS.pdf",
                    type: 'application/pdf',
                    disposition: 'inline'
        end
      end
    end

    def update
      # 1. Asigna los nuevos parámetros sin guardar en la BD todavía
      @service_order.assign_attributes(service_order_params)
    
      # 2. Ejecuta el recálculo con los nuevos valores recibidos
      calcular_totales(@service_order)
    
      # 3. Guarda los cambios
      if @service_order.save
        redirect_to admin_service_order_path(@service_order), notice: 'Orden actualizada exitosamente.'
      else
        @client_car = @service_order.client_car
        flash.now[:alert] = 'Error al actualizar la orden. Verifica los campos.'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      car = @service_order.client_car
      @service_order.destroy
      redirect_to admin_client_path(car.client), notice: 'Orden de servicio eliminada.'
    end

    private

    def set_client_car
      @client_car = ClientCar.find(params[:client_car_id])
    end

    def set_service_order
      @service_order = ServiceOrder.find(params[:id])
    end

    def calcular_totales(order)
      subtotal_servicios = order.order_services.reject(&:_destroy).sum { |s| (s.cantidad || 1) * (s.precio_unitario || 0.0) }
      subtotal_items = order.order_items.reject(&:_destroy).sum { |i| (i.cantidad || 1) * (i.precio_unitario || 0.0) }
      
      order.order_services.each { |s| s.precio_total = (s.cantidad || 1) * (s.precio_unitario || 0.0) }
      order.order_items.each { |i| i.precio_total = (i.cantidad || 1) * (i.precio_unitario || 0.0) }

      order.subtotal = subtotal_servicios + subtotal_items
      order.total = order.subtotal
    end

    def service_order_params
      params.require(:service_order).permit(
        :numero_orden, :codigo_orden, :fecha_entrada, :fecha_salida, :km_entrada, :km_salida, :tecnico, :forma_pago,
        order_services_attributes: [:id, :descripcion, :cantidad, :precio_unitario, :_destroy],
        order_items_attributes: [:id, :tipo, :descripcion, :cantidad, :precio_unitario, :_destroy]
      )
    end
  end
end