# app/controllers/admin/sales_controller.rb
module Admin
  class SalesController < Admin::ApplicationController
    before_action :set_current_user
    before_action :check_pending_devoluciones
    before_action :set_filters_data, only: [:movimientos_caja]
    layout 'dashboard'

    def index
      @sales = Sale.all
      
      # Búsqueda por código interno de venta
      if params[:code].present?
        query = /#{Regexp.escape(params[:code])}/i
        @sales = @sales.where(code: query)
      end

      if params[:start_date].present? && params[:end_date].present?
        start_date = DateTime.parse(params[:start_date]).beginning_of_day
        end_date   = DateTime.parse(params[:end_date]).end_of_day
        @sales = @sales.where(:sold_at.gte => start_date, :sold_at.lte => end_date)
      end

      @sales = @sales.order_by(sold_at: :desc)
    end

    def new
      @sale = Sale.new
    end

    def create
      if !@current_user.puede_vender?
        redirect_to admin_sales_new_path, alert: "Esta acción solo la puede hacer un cajero"
        return
      end

      @sale = Sale.new(sale_params)
      @sale.status = "confirmed"
      @sale.sold_at = Time.now
      @sale.user_id = @current_user.id

      if @sale.save
        create_product_histories(@sale)
        registrar_movimiento_caja(@sale) # Registra el movimiento centralizado de caja
        
        redirect_to admin_sales_path, notice: "Venta registrada con éxito. Código: #{@sale.code}"
      else
        flash.now[:alert] = "Error al registrar la venta: #{@sale.errors.full_messages.to_sentence}"
        render :new
      end
    end

    def detalle_venta
      @sale = Sale.find(params[:id])
      @product_sales = @sale.product_sales
    end

    def generate_pdf
      @sale = Sale.find(params[:id])
      pdf = SalePdf.new(@sale).generate
      send_data pdf,
                filename: "comprobante_#{@sale.code}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    end

    def available_products
      sale = Sale.find(params[:id])
      products = sale.products_available_for_return.map do |ps|
        {
          id: ps.id,
          name: ps.product.name,
          quantity: ps.quantity,
          price: ps.unit_price - (ps.discount || 0)
        }
      end
      render json: products
    end

    def search_by_code
      sale = Sale.where(code: params[:code]).first
      if sale && sale.has_products_available_for_return?
        render json: {
          id: sale.id.to_s,
          client_name: sale.client_name,
          products: sale.products_available_for_return.map do |ps|
            {
              id: ps.product_id.to_s,
              name: ps.product_name,
              quantity: ps.quantity,
              price: ps.unit_price - (ps.discount || 0)
            }
          end
        }
      else
        render json: { error: "Venta no encontrada o sin productos disponibles" }, status: :not_found
      end
    end

    def search_clients
      clients = Client.where(is_active: true)
      if params[:q].present?
        query = /#{Regexp.escape(params[:q])}/i
        clients = clients.where(nombre: query)
      end
      render json: clients.limit(10).as_json(only: [:_id, :nombre, :tipo_documento_id, :num_documento, :nrc, :email, :telefono, :direccion])
    end

    def movimientos_caja
      # Consulta base
      @movimientos = HeadMovimientoCaja.all

      # Si es Admin / Super Admin, filtramos opcionalmente por Sucursal y Caja
      if current_user.role.name = "admin" ||  current_user.role.name = "super_admin"
        if params[:sucursal_id].present?
          @movimientos = @movimientos.where(sucursal_id: params[:sucursal_id])
        end

        if params[:caja_id].present?
          @movimientos = @movimientos.where(caja_id: params[:caja_id])
        end
      else
        # Si es cajero o rol restrictivo, solo ve su sucursal/caja asignada
        cajero = Cajero.find_by(user_id: current_user.id)
        if cajero.present?
          @movimientos = @movimientos.where(caja_id: cajero.caja_id)
        end
      end

      # Otros filtros habituales (fechas, etc.)
      if params[:start_date].present? && params[:end_date].present?
        @movimientos = @movimientos.where(created_at: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
      end

      @movimientos = @movimientos.order(created_at: :desc)
    end

    def consultar_movimientos
      #binding.pry
      movimientos = HeadMovimientoCaja.all

      # 1. Control de Permisos y Filtro de Cajero
      if current_user.role&.name&.downcase == 'cajero'
        # current_user.id ya es de tipo BSON::ObjectId (o lo casteamos si viene de un params)
        cajero_obj_id = current_user.id.is_a?(BSON::ObjectId) ? current_user.id : BSON::ObjectId.from_string(current_user.id.to_s)
        movimientos = movimientos.where(cajero_id: cajero_obj_id)
      else
        # Filtros opcionales para Admin / Super Admin

        # Filtro por Caja
        if params[:caja_id].present?
          caja_id = BSON::ObjectId.from_string(params[:caja_id]) rescue params[:caja_id]
          movimientos = movimientos.where(caja_id: caja_id)
        end

        # Filtro por Sucursal
        if params[:sucursal_id].present?
          sucursal_id = BSON::ObjectId.from_string(params[:sucursal_id]) rescue params[:sucursal_id]
          movimientos = movimientos.where(sucursal_id: sucursal_id)
        end
        
        # Filtro por Cajero (Conversión a BSON::ObjectId)
        if params[:cajero_id].present?
          begin
            cajero_obj_id = BSON::ObjectId.from_string(params[:cajero_id])
            movimientos = movimientos.where(cajero_id: cajero_obj_id)
          rescue BSON::Error::InvalidObjectId
            # Si el string no es un ObjectId válido, intenta la búsqueda directa
            movimientos = movimientos.where(cajero_id: params[:cajero_id])
          end
        end
      end

      # 2. Filtro por Rango de Fechas
      if params[:fecha_desde].present?
        desde = Time.zone.parse(params[:fecha_desde]).beginning_of_day
        movimientos = movimientos.where(:created_at.gte => desde)
      end

      if params[:fecha_hasta].present?
        hasta = Time.zone.parse(params[:fecha_hasta]).end_of_day
        movimientos = movimientos.where(:created_at.lte => hasta)
      end

      # 3. Buscador General
      if params[:q].present?
        query = /#{Regexp.escape(params[:q])}/i
        movimientos = movimientos.any_of(
          { numero_control: query },
          { comprobante_codigo: query },
          { client_name: query },
          { codigo_generacion: query }
        )
      end

      # 4. Ordenamiento final
      @movimientos = movimientos.order_by(created_at: :desc)
      e = 2

      render layout: false
    end

    # Carga de HTML parcial para el Modal de Detalle
    def detalle_movimiento
      @movimiento = HeadMovimientoCaja.find(params[:id])

      if @movimiento.service_order_id.present?
        @service_order = ServiceOrder.where(id: @movimiento.service_order_id).first
      elsif @movimiento.sale_id.present?
        @sale = Sale.where(id: @movimiento.sale_id).first
        @product_sales = @sale ? @sale.product_sales : []
      else
        # Fallback por si existen registros previos con origen_id
        @service_order = ServiceOrder.where(id: @movimiento.origen_id).first
        if @service_order.blank?
          @sale = Sale.where(id: @movimiento.origen_id).first
          @product_sales = @sale ? @sale.product_sales : []
        end
      end

      render layout: false
    end

    # Descarga o visualización del comprobante
    def descargar_comprobante
      @movimiento = HeadMovimientoCaja.find(params[:id])
      # Aquí adaptas a tu lógica de generación de PDF o descarga de DTE en JSON/PDF
      respond_to do |format|
        format.html { redirect_to admin_sales_path, notice: "Descargando comprobante..." }
        format.pdf do
          # Lógica para renderizar tu PDF de comprobante
        end
      end
    end

    private

    def sale_params
      permitted = params.require(:sale).permit(
        :client_id,
        :client_name,
        :cajero_id,
        :caja_id,
        :sucursal_id,
        :tipo_documento_dte_id,
        :condicion_tributaria,
        :total_amount,
        product_sales_attributes: [:product_id, :quantity, :unit_price, :discount, :offer_type, :subtotal]
      )

      # Si en el modelo Sale el campo se llama :tipo_impuesto
      if permitted[:condicion_tributaria].present?
        permitted[:tipo_impuesto] = permitted.delete(:condicion_tributaria)
      end

      permitted
    end

    def registrar_movimiento_caja(sale)
      monto = sale.total_amount || 0.0
      
      # Si hay relación directa con el modelo Client registrado, traemos sus datos
      cliente_db = sale.client if sale.respond_to?(:client) && sale.client_id.present?

      head = HeadMovimientoCaja.new(
        comprobante_codigo: sale.code,
        origen_tipo: "VentaProducto",
        origen_id: sale.id,
        fecha: sale.sold_at,
        sucursal_id: sale.sucursal_id,
        caja_id: sale.caja_id,
        cajero_id: sale.cajero_id,
        tipo_documento_dte_id: sale.tipo_documento_dte_id,
        user_id: sale.user_id,
        monto_total: monto,
        
        # Guardado de la información del cliente (registrado o manual)
        client_id: sale.respond_to?(:client_id) ? sale.client_id : nil,
        client_name: sale.client_name,
        tipo_documento_cliente: cliente_db&.tipo_documento_id,
        num_documento_cliente: cliente_db&.num_documento,
        nrc_cliente: cliente_db&.nrc,
        email_cliente: cliente_db&.email,
        telefono_cliente: cliente_db&.telefono,
        direccion_cliente: cliente_db&.direccion
      )

      # Clasificación tributaria del total del comprobante
      case sale.condicion_tributaria
      when 'exento'
        head.total_exento = monto
      when 'no_sujeta'
        head.total_no_sujeta = monto
      else
        head.total_gravado = monto
      end

      head.save!

      # Registro del detalle en DetMovimientoCaja
      sale.product_sales.each do |ps|
        tipo_item = ps.product.respond_to?(:tipo_producto) && ps.product.tipo_producto == 'servicio' ? 'servicio' : 'producto'
        
        DetMovimientoCaja.create!(
          head_movimiento_caja_id: head.id,
          product_id: ps.product_id,
          item_nombre: ps.product&.name,
          tipo_item: tipo_item,
          cantidad: ps.quantity,
          precio_unitario: ps.unit_price,
          descuento: ps.discount || 0.0,
          condicion_tributaria: sale.condicion_tributaria || "gravado",
          subtotal: ps.subtotal || (ps.quantity * ps.unit_price)
        )
      end
    end

    def set_current_user
      @current_user = current_user
    end

    def check_pending_devoluciones
      if current_user && current_user.role && ["admin", "super_admin"].include?(current_user.role.name)
        @pending_devoluciones_count = Devolucion.where(is_authorized: false).count
      else
        @pending_devoluciones_count = 0
      end
    end

    def set_filters_data
      @sucursales = Sucursal.where(is_active: true)
      @cajas = Caja.where(is_active: true)
      @cajeros = Cajero.all # O la consulta para obtener cajeros
    end

    def create_product_histories(sale)
      sale.product_sales.each do |ps|
        ProductHistory.create!(
          product_id: ps.product_id,
          name: ps.product.name,
          code: ps.product.code,
          description: ps.product.description,
          quantity: ps.quantity,
          price: ps.unit_price,
          discount: ps.discount || 0,
          movement_type: "Salida",
          sale_id: sale.id,
          stock_before: ps.product.quantity + ps.quantity,
          current_stock: ps.product.quantity,
          user_id: @current_user.id
        )
      end
    end
  end
end