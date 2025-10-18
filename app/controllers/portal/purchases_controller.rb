class Portal::PurchasesController < ApplicationController
  before_action :set_current_user
  layout "dashboard"

  def index
    @purchases = UserSale.where(user_id: @current_user.id).map(&:sale)
  end

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end
end
