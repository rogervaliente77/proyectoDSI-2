# app/controllers/admin/marcas_controller.rb
module Admin
  class DeliveriesController < ApplicationController
    #before_action :authenticate_user! # Asegura que el usuario esté autenticado
    #before_action :set_marca, only: %i[edit update destroy]
    before_action :set_current_user
    layout 'dashboard'

    def index
      if current_user.role.name == "mensajero"
        mensajero = DeliveryDriver.where(user_id: current_user.id).first
        @deliveries = Delivery.where(delivery_driver_id: mensajero.id)
      else
        if params.present?
          @deliveries = Delivery.where(delivery_status: params[:delivery_status])
        else
          @deliveries = Delivery.all
        end
        
      end
      
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

        # html = ApplicationController.render(
        #   partial: "portal/purchases/delivery_status_real_time",
        #   locals: { sale: @delivery.sale }
        # )
      
        # # Envía actualización en tiempo real
        # ActionCable.server.broadcast(
        #   "delivery_status_#{@delivery.sale.id}",
        #   { html: html }
        # )

        redirect_to admin_pedidos_path, notice: "Mensajero asignado con éxito."
      else
        redirect_to admin_assign_to_delivery_driver_path(id: delivery.id), alert: "Mensajero no puso ser asignado"
      end
    end

    def change_delivery_status
      @delivery = Delivery.find(params[:id])

      if @delivery.delivery_status == "assigned"
        @delivery.delivery_status = "picked_up"
        @delivery.package_status = "picked_up"
        @delivery.picked_up_at = Time.now
      elsif @delivery.delivery_status == "picked_up"
        @delivery.delivery_status = "in_route"
        @delivery.in_route_at = Time.now
      elsif @delivery.delivery_status == "in_route"
        @delivery.delivery_status = "onsite"
        @delivery.onsite_at = Time.now
      elsif @delivery.delivery_status == "onsite"
        if params[:delivery_action] == "success"
          @delivery.delivery_status = "delivered"
          @delivery.delivered_at = Time.now
          @delivery.was_delivered = true
        else
          @delivery.delivery_status = "rejected"
          @delivery.rejected_at = Time.now
        end
      elsif @delivery.delivery_status == "rejected"
        @delivery.delivery_status = "returned_to_warehouse"
        @delivery.returned_to_warehouse_at = Time.now
      elsif @delivery.delivery_status == "returned_to_warehouse"

      end
      
      if @delivery.save
        redirect_to admin_pedidos_path, notice: "Delivery actualizado con éxito."
      else
        redirect_to admin_pedidos_path, alert: "Pedido no puso ser actualizado"
      end
    end

    # field :package_status, type: String, default: "in_warehouse" #picked_up
    # field :delivery_status, type: String, default: "unassigned"  #assigned, picked_up, in_route, onsite, delivered, rejected, returned_to_warehouse

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

    def set_current_user
      @current_user = current_user
    end
  end
end
