module Admin
  class OnlineSalesController < ApplicationController
    layout 'dashboard'

    def index
      @online_sales = Sale.where(online_order: true).order_by(created_at: :desc)
    end

    # Acción para apagar el timbre persistente de nueva venta
    def acknowledge
      @sale = Sale.find(params[:id])
      @sale.update(admin_acknowledged: true)
      render json: { success: true }
    end

    def update_status
      @sale = Sale.find(params[:id])
      new_status = params[:new_status]
    
      # Guardamos el estado de pago anterior para comparar
      previous_payment_status = @sale.payment_status

      forma_pago_obj = FormaPago.where(codigo: @sale.forma_pago).first
      nombre_forma_pago = forma_pago_obj&.name.to_s.upcase

      # Determinamos reglas de pago según el nuevo estatus
      payment_update = @sale.payment_status
      if ['payment_approved', 'paid', 'delivered'].include?(new_status) && nombre_forma_pago.include?('TRANSFERENCIA')
        payment_update = 'paid'
      elsif new_status == 'delivered' && !nombre_forma_pago.include?('EFECTIVO')
        payment_update = 'paid' # Contra entrega (efectivo/tarjeta/etc.) pagada al entregar
      end
    
      comment = "Estado actualizado a: #{new_status.titleize}"
    
      if @sale.update_status_with_log(new_status, current_user.id, comment, payment_update)
        
        # 🚀 Si el pago acaba de volverse 'paid' y aún no tiene un HeadMovimientoCaja registrado
        if @sale.payment_status == 'paid' && previous_payment_status != 'paid'
          unless HeadMovimientoCaja.where(sale_id: @sale.id).exists?
            process_online_paid_sale!(@sale)
          end
        end

        ActionCable.server.broadcast("admin_online_sales", { 
          action: "update_status", 
          sale_id: @sale.id.to_s, 
          code: @sale.code,
          status: @sale.status,
          payment_status: @sale.payment_status
        })
    
        redirect_to admin_online_sales_path, notice: "La orden #{@sale.code} fue actualizada correctamente."
      else
        redirect_to admin_online_sales_path, alert: "No se pudo actualizar el estado de la orden."
      end
    end

    private

    # Método para procesar el inventario, kardex y movimiento de caja en ventas online pagadas
    def process_online_paid_sale!(sale)
      # 1. Registrar movimiento de caja (idéntico a ventas de caja)
      registrar_movimiento_caja(sale)

      # 2. Descontar stock y generar ProductHistory por cada producto de la compra
      sale.product_sales.each do |ps|
        product = ps.product
        next unless product && product.producto? # Ignoramos servicios

        current_qty = product.quantity.to_i
        new_qty = current_qty - ps.quantity.to_i

        # Desactivamos callbacks de update de producto temporalmente
        product.skip_history_callbacks = true
        product.quantity = new_qty
        product.save!

        concepto = "Egreso de inventario por venta en línea #{sale.code}"

        ProductHistory.create!(
          product_id: product.id,
          name: product.name,
          description: product.description,
          code: product.code,
          quantity: ps.quantity,
          price: ps.unit_price,
          discount: ps.discount || 0,
          cash_in: (ps.unit_price - (ps.unit_price * ((ps.discount || 0).to_f / 100))) * ps.quantity,
          sale_id: sale.id,
          movement_type: "2", # 2 = Egreso
          concepto: concepto,
          stock_before: current_qty,
          current_stock: new_qty,
          user_id: current_user.id
        )
      end
    end

    def registrar_movimiento_caja(sale)
      monto = sale.total_amount || 0.0

      # Si hay relación directa con el modelo Client registrado, traemos sus datos
      cliente_db = sale.client if sale.respond_to?(:client) && sale.client_id.present?

      head = HeadMovimientoCaja.new(
        comprobante_codigo: sale.code,
        origen_tipo: 'VentaProducto',
        origen_id: sale.id,
        fecha: sale.respond_to?(:sold_at) && sale.sold_at.present? ? sale.sold_at : Time.current,
        sucursal_id: sale.sucursal_id,
        caja_id: sale.caja_id,
        cajero_id: sale.cajero_id,
        tipo_documento_dte_id: sale.tipo_documento_dte_id,
        user_id: sale.user_id || current_user.id,
        monto_total: monto,

        # Relación con sale
        sale_id: sale.id,

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
          condicion_tributaria: sale.condicion_tributaria || 'gravado',
          subtotal: ps.subtotal || (ps.quantity * ps.unit_price)
        )
      end
    end
  end
end