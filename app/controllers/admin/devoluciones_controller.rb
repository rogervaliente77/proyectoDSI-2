# app/controllers/admin/devoluciones_controller.rb
module Admin
  class DevolucionesController < ApplicationController
    #before_action :authenticate_user! # Asegura que el usuario esté autenticado

    before_action :set_devolucion, only: %i[edit update destroy]
    layout 'dashboard'

    def index
  @devoluciones = Devolucion.all.order_by(created_at: :desc)
    end

    def new
  @devolucion = Devolucion.new
  @ventas_disponibles = Sale.all.select(&:has_products_available_for_return?)
    end


    def create
      @devolucion = Devolucion.new(devolucion_params)
      if @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolucion creada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @devolucion.update(devolucion_params)
        redirect_to admin_devoluciones_path, notice: "Devolucion actualizada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @devolucion.destroy
        redirect_to admin_devoluciones_path, notice: "Devolucion eliminada exitosamente", status: :see_other
      else
        redirect_to admin_devoluciones_path, alert: "No se pudo eliminar la devolucion", status: :unprocessable_entity
      end
    end

    private

    def set_devolucion
      @devolucion = Devolucion.find(params[:id])
      unless @devolucion
        redirect_to admin_devoluciones_path, alert: "Devolucion no encontrada"
      end
    end

    def devolucion_params
      params.require(:devolucion).permit(:client_id, :client_name, :fecha_devolucion, :comments_devolucion, 
                                        :caja_id, :cajero_id, :sale_id, sale_devolucion_detalle: [] )
    end
  end
end