# app/controllers/admin/marcas_controller.rb
module Admin
  class DeliveriesController < ApplicationController
    #before_action :authenticate_user! # Asegura que el usuario esté autenticado
    #before_action :set_marca, only: %i[edit update destroy]
    layout 'dashboard'

    def index
      @deliveries = Delivery.all
    end

    def assign_to_delivery_driver
      @delivery = Delivery.find(params[:id])

      active_deliveries = Delivery.where(
        delivery_status: "in_route",
        was_delivered: false
      )

      busy_driver_ids = active_deliveries.distinct(:delivery_driver_id)

      @available_drivers = DeliveryDriver.where(
        :id.nin => busy_driver_ids,
        disabled: false
      )

      Rails.logger.info "Active deliveries: #{active_deliveries.count}"
      Rails.logger.info "Busy drivers: #{busy_driver_ids}"
      Rails.logger.info "Available drivers: #{@available_drivers.count}"

    end

    def save_delivery_driver_in_delivery
      @delivery = Delivery.find(params[:delivery][:delivery_id])
      @delivery.delivery_driver_id = params[:delivery][:delivery_driver_id]
      # @delivery.package_status = "picked_up"
      @delivery.delivery_status = "assigned"
      if @delivery.save

        html = ApplicationController.render(
          partial: "portal/purchases/delivery_status_real_time",
          locals: { sale: @delivery.sale }
        )
      
        # Envía actualización en tiempo real
        ActionCable.server.broadcast(
          "delivery_status_#{@delivery.sale.id}",
          { html: html }
        )

        redirect_to admin_pedidos_path, notice: "Mensajero asignado con éxito."
      else
        redirect_to admin_assign_to_delivery_driver_path(id: delivery.id), alert: "Mensajero no puso ser asignado"
      end
    end

    def create
      @marca = Marca.new(marca_params)
      if @marca.save
        redirect_to admin_marcas_path, notice: "Marca creada con éxito."
      else
        flash[:alert] = @marca.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @marca.update(marca_params)
        redirect_to admin_marcas_path, notice: "Marca actualizada con éxito."
      else
        flash[:alert] = @marca.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @marca.destroy
        redirect_to admin_marcas_path, notice: "Marca eliminada exitosamente", status: :see_other
      else
        redirect_to admin_marcas_path, alert: "No se pudo eliminar la marca", status: :unprocessable_entity
      end
    end

    private

    def set_marca
      @marca = Marca.find_by(id: params[:id])
      unless @marca
        redirect_to admin_marcas_path, alert: "Marca no encontrada"
      end
    end

    def marca_params
      params.require(:marca).permit(:name, :description)
    end
  end
end
