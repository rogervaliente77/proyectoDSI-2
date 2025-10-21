class Portal::PurchasesController < ApplicationController
  before_action :set_current_user
  layout "dashboard"

  def index
    # Traer todas las compras del usuario
    @purchases = Sale.where(client_id: @current_user.id).order(sold_at: :desc)
  end

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end
end




