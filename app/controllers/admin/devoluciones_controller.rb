module Admin
  class DevolucionesController < ApplicationController
    before_action :set_devolucion, only: %i[edit update destroy]
    layout 'dashboard'

    def index
      @devoluciones = Devolucion.all.order_by(created_at: :desc)
    end

    def new
      @devolucion = Devolucion.new
    end

    def create
      @devolucion = Devolucion.new(devolucion_params)

      # Ajustar cada detalle con precios y descuento
      detalles = (@devolucion.sale_devolucion_detalle || []).map do |detalle|
        product = Product.find_by(id: detalle["product_id"])
        next unless product

        {
          "product_id" => product.id.to_s,
          "cantidad" => detalle["cantidad"].to_i,
          "precio_unitario" => product.price.to_f,
          "descuento" => product.discount.to_f,
          "precio_con_descuento" => (product.price.to_f * (1 - product.discount.to_f / 100)).round(2)
        }
      end.compact

      @devolucion.sale_devolucion_detalle = detalles
      @devolucion.calcular_total

      if @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolución creada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
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
          precio_con_descuento: detalle["precio_con_descuento"].to_f
        }
      end
    end

    def update
      if devolucion_params[:sale_devolucion_detalle]
        detalles = devolucion_params[:sale_devolucion_detalle].map do |detalle|
          product = Product.find_by(id: detalle["product_id"])
          next unless product

          {
            "product_id" => product.id.to_s,
            "cantidad" => detalle["cantidad"].to_i,
            "precio_unitario" => product.price.to_f,
            "descuento" => product.discount.to_f,
            "precio_con_descuento" => (product.price.to_f * (1 - product.discount.to_f / 100)).round(2)
          }
        end.compact

        @devolucion.sale_devolucion_detalle = detalles
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

    def autorizar_devolucion
      @devolucion = Devolucion.find(params[:id])

      if !@devolucion.is_authorized
        @devolucion.authorized_at = Time.current

        (@devolucion.sale_devolucion_detalle || []).each do |detalle|
          next if detalle["cantidad"].to_f <= 0
          product = Product.find_by(id: detalle["product_id"])
          next unless product

          ReturnedProduct.create!(
            product: product,
            sale: @devolucion.sale,
            devolucion: @devolucion,
            quantity: detalle["cantidad"].to_i,
            unit_price: detalle["precio_con_descuento"].to_f,
            discount: detalle["descuento"].to_f,
            returned_at: Time.current
          )
        end
      else
        @devolucion.authorized_at = nil
      end

      @devolucion.update(is_authorized: !@devolucion.is_authorized, authorized_at: @devolucion.authorized_at)
      redirect_to admin_devoluciones_path, notice: "Devolución actualizada exitosamente", status: :see_other
    end

    private

    def set_devolucion
      @devolucion = Devolucion.find(params[:id])
      redirect_to admin_devoluciones_path, alert: "Devolución no encontrada" unless @devolucion
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
        sale_devolucion_detalle: [:product_id, :cantidad]
      )
    end
  end
end
