class LandingController < ApplicationController
  before_action :set_current_user
  layout 'landing'

  def index
    @categories = Category.all
    # Carga de productos optimizada con sus asociaciones
    @products = Product.includes(:category, :marca, :car_type).where(kind: "producto")
    @services = Product.where(kind: "servicio")
  end

  # Acción para aceptar notificaciones
  def accept_notifications
    if current_user
      current_user.update(allow_notifications: true)
      head :ok
    else
      head :unauthorized
    end
  end

  private

  def set_current_user
    @current_user = current_user
  end
end
