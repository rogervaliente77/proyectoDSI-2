module Portal
  class CartsController < ApplicationController
    before_action :authenticate_user! # Asegura que el cliente esté autenticado

    def create_order
      items = params[:items] || []

      unless business_hours?
        render json: { success: false, error: "Lo sentimos, nuestro horario de atención en línea es de Lunes a Sábado de 8:00 AM a 5:00 PM." }, status: :unprocessable_entity
        return
      end
      
      if items.empty?
        render json: { success: false, error: "El carrito está vacío" }, status: :unprocessable_entity
        return
      end

      # 1. Obtener datos del cliente actual registrado en la plataforma
      client = Client.find_by(email: current_user.email) || Client.find_by(telefono: current_user.phone_number)
      
      unless client
        render json: { success: false, error: "No se encontró un perfil de cliente asociado a tu cuenta." }, status: :unprocessable_entity
        return
      end

      # 2. Localizar Sucursal, Caja y Cajero Virtuales (E-commerce)
      sucursal = Sucursal.first
      caja     = Caja.find_by(nombre: "Caja Web") || Caja.first
      cajero   = Cajero.find_by(nombre: "Cajero Sistema") || Cajero.first

      unless sucursal && caja && cajero
        render json: { success: false, error: "Faltan configuraciones de caja/cajero virtual en el sistema." }, status: :internal_server_error
        return
      end

      # 3. Calcular montos y armar los atributos anidados para ProductSale
      total_amount = 0.0
      product_sales_attributes = []

      items.each do |item|
        product = Product.where(id: item[:product_id]).first
        next unless product

        qty = item[:quantity].to_i
        price = item[:unit_price].to_f
        subtotal = qty * price
        total_amount += subtotal

        product_sales_attributes << {
          product_id: product.id,
          quantity: qty,
          unit_price: price,
          subtotal: subtotal,
          discount: 0.0,
          discount_porcentage: 0.0,
          offer_type: ""
        }
      end

      # 4. Determinar si es transferencia para asignar el estatus inicial correcto
      payment_method = params[:payment_method]
      initial_status = (payment_method == 'TRANSFERENCIA') ? 'pending_payment_comprob' : 'confirmed'

      # 5. Construir la Venta (Sale)
      @sale = Sale.new(
        online_order: true,
        admin_acknowledged: false,
        status: initial_status,
        sold_at: Time.current,
        total_amount: total_amount,
        forma_pago: payment_method,
        delivery_method: params[:delivery_method],
        was_delivered: false,
        tipo_impuesto: "gravado",
        condicion_tributaria: "gravado",
        
        # Relaciones
        client: client,
        client_name: client.nombre,
        user_id: current_user.id,
        sucursal_id: sucursal.id,
        caja_id: caja.id,
        cajero_id: cajero.id,
        
        product_sales_attributes: product_sales_attributes
      )

      # Forzar un prefijo personalizado "WEB-" en el código interno de la venta
      date_str = Date.today.strftime("%Y-%m-%d")
      count_today = Sale.where(:created_at.gte => Date.today.beginning_of_day).count
      @sale.code = "WEB-#{date_str}-#{(count_today + 1).to_s.rjust(3, '0')}"

      if @sale.save

        ActionCable.server.broadcast("admin_online_sales", { 
          action: "new_sale", 
          sale_id: @sale.id.to_s, 
          code: @sale.code,
          client_name: client.nombre,
          total_amount: @sale.total_amount,
          delivery_method: @sale.delivery_method,
          status: @sale.status
        })

        if @sale.delivery_method == 'delivery'
          Delivery.create!(
            sale: @sale,
            sale_code: @sale.code,
            client_name: client.nombre,
            client_id: client.id,
            delivery_address: client.direccion,
            delivery_status: 'unassigned',
            package_status: 'in_warehouse'
          )
        end

        # Registrar bitácora de estado inicial según el método de pago
        log_comment = if payment_method == 'TRANSFERENCIA'
                        "Pedido creado en línea. Pendiente de comprobante de transferencia."
                      else
                        "Pedido realizado en línea con pago en efectivo (contra entrega)."
                      end

        @sale.update_status_with_log(initial_status, current_user.id, log_comment)

        # Si es pago en efectivo (confirmed), aplicamos caja e inventario de inmediato.
        # Si es transferencia (pending_payment_comprob), se omiten hasta que el taller valide el comprobante.
        if payment_method != 'TRANSFERENCIA'
          registrar_movimiento_caja_online(@sale, client)
          create_product_histories_online(@sale, current_user.id)
        end

        render json: { success: true, code: @sale.code }, status: :ok
      else
        render json: { success: false, error: @sale.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    private

    def registrar_movimiento_caja_online(sale, client)
      monto = sale.total_amount || 0.0

      head = HeadMovimientoCaja.new(
        comprobante_codigo: sale.code,
        origen_tipo: 'VentaProducto',
        origen_id: sale.id,
        fecha: sale.sold_at,
        sucursal_id: sale.sucursal_id,
        caja_id: sale.caja_id,
        cajero_id: sale.cajero_id,
        tipo_documento_dte_id: sale.tipo_documento_dte_id,
        user_id: sale.user_id,
        monto_total: monto,
        sale_id: sale.id,
        
        # Datos del cliente
        client_id: client.id,
        client_name: client.nombre,
        tipo_documento_cliente: client.tipo_documento_id,
        num_documento_cliente: client.num_documento,
        nrc_cliente: client.nrc,
        email_cliente: client.email,
        telefono_cliente: client.telefono,
        direccion_cliente: client.direccion
      )

      head.total_gravado = monto
      head.save!

      sale.product_sales.each do |ps|
        DetMovimientoCaja.create!(
          head_movimiento_caja_id: head.id,
          product_id: ps.product_id,
          item_nombre: ps.product&.name,
          tipo_item: 'producto',
          cantidad: ps.quantity,
          precio_unitario: ps.unit_price,
          descuento: 0.0,
          condicion_tributaria: 'gravado',
          subtotal: ps.subtotal
        )
      end
    end

    def create_product_histories_online(sale, user_id)
      sale.product_sales.each do |ps|
        ProductHistory.create!(
          product_id: ps.product_id,
          name: ps.product.name,
          code: ps.product.code,
          description: ps.product.description,
          quantity: ps.quantity,
          price: ps.unit_price,
          discount: 0,
          movement_type: 'Salida',
          sale_id: sale.id,
          stock_before: ps.product.quantity + ps.quantity,
          current_stock: ps.product.quantity,
          user_id: user_id
        )
      end
    end

    def business_hours?
      now = Time.current
      # Lunes (1) a Sábado (6), de 8:00 AM a 5:00 PM (17:00)
      working_days = (1..6).include?(now.wday)
      working_hours = (8...18).include?(now.hour)

      working_days && working_hours
    end
  end
end