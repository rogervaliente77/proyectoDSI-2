class Portal::PurchasesController < ApplicationController
  before_action :set_current_user
  before_action :set_header_variables  # <-- Esto es nuevo
  layout "dashboard"

  def index
    # Traer todas las compras del usuario
    @purchases = Sale.where(client_id: @current_user.id).order(sold_at: :desc)
  end

  private

  # Mantener current_user
  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  # ----------------- NUEVO -----------------
  # Variables necesarias para el headerbar
  def set_header_variables
    if @current_user&.role&.name == 'cliente'
      @offer_products = Product.all.select(&:on_offer?)
    else
      @offer_products = []
    end
  end
end
