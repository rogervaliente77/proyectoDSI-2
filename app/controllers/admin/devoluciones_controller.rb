module Admin
  class DevolucionesController < ApplicationController
    before_action :set_devolucion, only: %i[edit update destroy autorizar_devolucion]
    layout 'dashboard'

    def index
      @devoluciones = Devolucion.all.order(created_at: :desc)
    end

    def new
      @devolucion = Devolucion.new
    end

    def create
      @devolucion = Devolucion.new(devolucion_params)
      @devolucion.calcular_total
      if @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolución creada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # 👇 Aquí obtenemos los productos relacionados y el total
      @productos = @devolucion.sale_devolucion_detalle || []
      @total_devolver = @productos.sum { |p| p["cantidad"].to_f * p["precio_unitario"].to_f }
    end

    def update
      if @devolucion.update(devolucion_params)
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
      @devolucion.update(is_authorized: !@devolucion.is_authorized)

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
        sale_devolucion_detalle: [:product_id, :cantidad, :precio_unitario]
      )
    end
  end
end
