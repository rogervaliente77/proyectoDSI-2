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
          car_ids = @client.client_cars.pluck(:id)
          @service_orders = @service_orders.where(:client_car_id.in => car_ids)
        end
      end
    end

    def show; end

    def new
      @service_order = @client_car.service_orders.build
      @service_order.preparar_correlativos
      @service_order.order_services.build
      @service_order.order_items.build
      cargar_catalogos
    end

    def create
      @service_order = @client_car.service_orders.build(service_order_params)
      
      # Asignación de contexto operativo / cajero / usuario
      @service_order.user_id = current_user.id
      cajero = Cajero.find_by(user_id: current_user.id)
      
      if cajero.present?
        @service_order.cajero_id = cajero.id
        @service_order.caja_id = cajero.caja_id
        @service_order.sucursal_id = cajero.sucursal_id || (cajero.caja.present? ? cajero.caja.sucursal_id : nil)
      end

      calcular_totales(@service_order)

      if @service_order.save
        registrar_movimiento_caja(@service_order) # <--- Registro en HeadMovimientoCaja
        redirect_to admin_service_order_path(@service_order), notice: 'Orden de servicio y movimiento DTE registrados con éxito.'
      else
        cargar_catalogos
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @client_car = @service_order.client_car
      cargar_catalogos
    end

    def update
      @service_order.assign_attributes(service_order_params)
      calcular_totales(@service_order)

      if @service_order.save
        redirect_to admin_service_order_path(@service_order), notice: 'Orden actualizada exitosamente.'
      else
        @client_car = @service_order.client_car
        cargar_catalogos
        flash.now[:alert] = 'Error al actualizar la orden. Verifica los campos.'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      car = @service_order.client_car
      @service_order.destroy
      redirect_to admin_client_path(car.client), notice: 'Orden de servicio eliminada.'
    end

    def print_pdf
      pdf = GenerateMantenimientoServicePdf.new(@service_order)
      respond_to do |format|
        format.pdf do
          send_data pdf.render, filename: "Orden_#{@service_order.numero_orden}_BIMERS.pdf", type: 'application/pdf', disposition: 'inline'
        end
        format.all do
          send_data pdf.render, filename: "Orden_#{@service_order.numero_orden}_BIMERS.pdf", type: 'application/pdf', disposition: 'inline'
        end
      end
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
        :numero_orden, :codigo_orden, :fecha_entrada, :fecha_salida, :km_entrada, :km_salida, 
        :tecnico, :forma_pago, :tipo_documento_dte_id, :condicion_tributaria, :caja_id, :sucursal_id, :cajero_id,
        order_services_attributes: [:id, :descripcion, :cantidad, :precio_unitario, :_destroy],
        order_items_attributes: [:id, :tipo, :descripcion, :cantidad, :precio_unitario, :_destroy]
      )
    end

    def registrar_movimiento_caja(order)
      monto = order.total || 0.0
      cliente = order.client_car&.client

      # 1. Crear cabecera del movimiento (Aquí `HeadMovimientoCaja` generará la numeración DTE correspondiente)
      head = HeadMovimientoCaja.new(
        comprobante_codigo: order.codigo_orden,
        origen_tipo: "VentaServicio",
        origen_id: order.id,
        service_order_id: order.id,
        fecha: Time.current,
        sucursal_id: order.sucursal_id,
        caja_id: order.caja_id,
        cajero_id: order.cajero_id,
        tipo_documento_dte_id: order.tipo_documento_dte_id,
        user_id: order.user_id,
        monto_total: monto,
        
        # Datos del cliente
        client_id: cliente&.id,
        client_name: cliente&.nombre || 'Cliente General',
        tipo_documento_cliente: cliente&.tipo_documento_id,
        num_documento_cliente: cliente&.num_documento,
        nrc_cliente: cliente&.nrc,
        email_cliente: cliente&.email,
        telefono_cliente: cliente&.telefono,
        direccion_cliente: cliente&.direccion
      )

      # Clasificación tributaria
      case order.condicion_tributaria
      when 'exento'
        head.total_exento = monto
      when 'no_sujeta'
        head.total_no_sujeta = monto
      else
        head.total_gravado = monto
      end

      head.save!

      # 2. Registrar Servicios en DetMovimientoCaja
      order.order_services.each do |serv|
        cant = serv.cantidad || 1.0
        precio = serv.precio_unitario || 0.0
        DetMovimientoCaja.create!(
          head_movimiento_caja_id: head.id,
          item_nombre: serv.descripcion,
          tipo_item: "servicio",
          cantidad: cant,
          precio_unitario: precio,
          descuento: 0.0,
          condicion_tributaria: order.condicion_tributaria || "gravado",
          subtotal: cant * precio
        )
      end

      # 3. Registrar Repuestos/Insumos en DetMovimientoCaja
      order.order_items.each do |item|
        cant = item.cantidad || 1.0
        precio = item.precio_unitario || 0.0
        DetMovimientoCaja.create!(
          head_movimiento_caja_id: head.id,
          item_nombre: item.descripcion,
          tipo_item: "producto",
          cantidad: cant,
          precio_unitario: precio,
          descuento: 0.0,
          condicion_tributaria: order.condicion_tributaria || "gravado",
          subtotal: cant * precio
        )
      end
    end

    def cargar_catalogos
      @tipos_dte = TipoDocumentoDte.all
      @formas_pago = FormaPago.all if defined?(FormaPago)
    end
  end
end