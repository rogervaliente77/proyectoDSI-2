# app/controllers/admin/devoluciones_controller.rb
module Admin
  class DevolucionesController < ApplicationController
    before_action :set_devolucion, only: %i[edit update destroy autorizar_devolucion generate_pdf]
    before_action :check_pending_devoluciones
    layout 'dashboard'

    def index
      @devoluciones = Devolucion.all.order_by(created_at: :desc)

      if params[:start_date].present? && params[:end_date].present?
        start_date = DateTime.parse(params[:start_date]).beginning_of_day
        end_date   = DateTime.parse(params[:end_date]).end_of_day
        @devoluciones = @devoluciones.where(:fecha_devolucion.gte => start_date, :fecha_devolucion.lte => end_date)
      end
    end

    def generate_report
      start_date = params[:start_date].present? ? DateTime.parse(params[:start_date]).beginning_of_day : nil
      end_date   = params[:end_date].present? ? DateTime.parse(params[:end_date]).end_of_day : nil

      devoluciones = Devolucion.all
      devoluciones = devoluciones.where(:fecha_devolucion.gte => start_date, :fecha_devolucion.lte => end_date) if start_date && end_date

      pdf = DevolucionesReportPdf.new(devoluciones, start_date, end_date).generate

      send_data pdf,
                filename: "reporte_devoluciones_#{Time.now.strftime('%Y%m%d')}.pdf",
                type: "application/pdf",
                disposition: "inline"
    end

    def generate_pdf
      pdf = DevolucionPdf.new(@devolucion).generate

      send_data pdf,
                filename: "devolucion_#{@devolucion.id}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    end
    
    def new
      @devolucion = Devolucion.new
    end

    def create
      @devolucion = Devolucion.new(devolucion_params)
      @devolucion.fecha_devolucion ||= Time.current
      procesar_detalles_devolucion

      if @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolución registrada exitosamente."
      else
        redirect_to admin_devoluciones_path, alert: "Error al registrar la devolución: #{@devolucion.errors.full_messages.join(', ')}"
      end
    end

    def edit
      @productos = []
      (@devolucion.sale_devolucion_detalle || []).each do |detalle|
        product = Product.find_by(id: detalle["product_id"])
        next unless product

        @productos << {
          product: product,
          cantidad: detalle["cantidad"].to_i,
          precio_unitario: detalle["precio_unitario"].to_f,
          descuento: detalle["descuento"].to_f,
          precio_con_descuento: detalle["precio_con_descuento"].to_f,
          condicion: detalle["condicion"] || "buen_estado"
        }
      end
    end

    def update
      if devolucion_params[:sale_devolucion_detalle]
        @devolucion.sale_devolucion_detalle = devolucion_params[:sale_devolucion_detalle]
        procesar_detalles_devolucion
      end

      if @devolucion.update(devolucion_params.except(:sale_devolucion_detalle))
        @devolucion.calcular_total
        @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolución actualizada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @devolucion.destroy
        redirect_to admin_devoluciones_path, notice: "Devolución eliminada exitosamente", status: :see_other
      else
        redirect_to admin_devoluciones_path, alert: "No se pudo eliminar la devolución", status: :unprocessable_entity
      end
    end

    # Autorizar devolución: ajusta inventarios (normal vs defectuoso) y crea kardex
    def autorizar_devolucion
      if !@devolucion.is_authorized
        @devolucion.authorized_at = Time.current

        @devolucion.sale_devolucion_detalle.each do |detalle|
          qty = detalle["cantidad"].to_i
          next if qty <= 0

          product = Product.find_by(id: detalle["product_id"])
          next unless product

          condicion = detalle["condicion"] || "buen_estado"
          precio_unitario = detalle["precio_con_descuento"].to_f

          # 1. Crear registro de ReturnedProduct
          ReturnedProduct.create!(
            product: product,
            sale: @devolucion.sale,
            devolucion: @devolucion,
            quantity: qty,
            unit_price: precio_unitario,
            discount: detalle["descuento"].to_f,
            condicion: condicion,
            returned_at: Time.current
          )

          # 2. Reingreso al Inventario según condición
          stock_anterior = product.quantity.to_i
          product.skip_history_callbacks = true

          if condicion == "defectuoso"
            product.defective_quantity = product.defective_quantity.to_i + qty
          else
            product.quantity = stock_anterior + qty
          end
          product.save!

          # 3. Registrar en el Kardex (ProductHistory)
          concepto = "Ingreso por devolución (#{condicion == 'defectuoso' ? 'Producto Defectuoso' : 'Buen Estado'}) - Orden #{@devolucion.sale&.code}"
          
          ProductHistory.create!(
            product_id: product.id,
            name: product.name,
            description: product.description,
            code: product.code,
            quantity: qty,
            price: precio_unitario,
            discount: detalle["descuento"].to_f,
            cash_in: 0, # No genera flujo de caja de ingreso
            sale_id: @devolucion.sale_id,
            movement_type: "1", # 1 = Ingreso
            concepto: concepto,
            stock_before: stock_anterior,
            current_stock: product.quantity,
            user_id: current_user.id
          )
        end

        # 4. Registrar en los logs de la venta
        sale = @devolucion.sale
        if sale.present?
          comment = "Devolución #{@devolucion.tipo_devolucion.capitalize} Autorizada por $#{'%.2f' % @devolucion.total_a_devolver}"
          sale.update_status_with_log(sale.status, current_user.id, comment, sale.payment_status)
        end

        @devolucion.is_authorized = true
        @devolucion.authorized_at = Time.current
        notice_msg = "Devolución autorizada correctamente. Inventario y Kardex actualizados."
      else
        @devolucion.is_authorized = false
        @devolucion.authorized_at = nil
        notice_msg = "Devolución marcada como no autorizada."
      end

      @devolucion.save
      redirect_to admin_devoluciones_path, notice: notice_msg, status: :see_other
    end

    def api_sale_details
      sale = Sale.find(params[:sale_id])
      if sale
        render json: {
          client_name: sale.client_name || 'Público General',
          products: sale.product_sales.map { |ps|
            {
              product_id: ps.product_id.to_s,
              name: ps.product&.name || 'Producto',
              max_quantity: ps.quantity,
              unit_price: ps.unit_price,
              subtotal: ps.subtotal
            }
          }
        }
      else
        render json: { error: "Venta no encontrada" }, status: :not_found
      end
    rescue Mongoid::Errors::DocumentNotFound
      render json: { error: "Venta no encontrada" }, status: :not_found
    end

    private

    def set_devolucion
      @devolucion = Devolucion.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to admin_devoluciones_path, alert: "Devolución no encontrada"
    end

    def procesar_detalles_devolucion
      detalles = (@devolucion.sale_devolucion_detalle || []).map do |detalle|
        product = Product.find_by(id: detalle["product_id"])
        next unless product

        qty = detalle["cantidad"].to_i
        precio = product.price.to_f
        desc = product.discount.to_f
        precio_desc = (precio * (1 - desc / 100.0)).round(2)

        {
          "product_id" => product.id.to_s,
          "cantidad" => qty,
          "precio_unitario" => precio,
          "descuento" => desc,
          "precio_con_descuento" => precio_desc,
          "condicion" => detalle["condicion"].presence || "buen_estado"
        }
      end.compact

      @devolucion.sale_devolucion_detalle = detalles
      @devolucion.calcular_total
    end

    def devolucion_params
      params.require(:devolucion).permit(
        :client_id,
        :client_name,
        :fecha_devolucion,
        :comments_devolucion,
        :caja_id,
        :cajero_id,
        :sale_id,
        sale_devolucion_detalle: [:product_id, :cantidad, :condicion]
      )
    end

    def check_pending_devoluciones
      if current_user && current_user.role && ["admin", "super_admin"].include?(current_user.role.name)
        @pending_devoluciones_count = Devolucion.where(is_authorized: false).count
      else
        @pending_devoluciones_count = 0
      end
    end
  end
end