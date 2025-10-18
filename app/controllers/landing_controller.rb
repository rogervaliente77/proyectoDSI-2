class LandingController < ApplicationController
  before_action :set_current_user

  def index
    @categories = Category.all
    @marcas = Marca.all
    @products = Product.includes(:category, :marca).all

    # ----------------- FILTROS -----------------
    @products = @products.where(name: /#{Regexp.escape(params[:query])}/i) if params[:query].present?
    @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
    @products = @products.where(marca_id: params[:marca_id]) if params[:marca_id].present?

    min_price = params[:min_price].present? ? params[:min_price].to_f : nil
    max_price = params[:max_price].present? ? params[:max_price].to_f : nil

    if min_price && max_price
      @products = @products.where(:price.gte => min_price, :price.lte => max_price)
    elsif min_price
      @products = @products.where(:price.gte => min_price)
    elsif max_price
      @products = @products.where(:price.lte => max_price)
    end

    if params[:offer].present? && params[:offer] != "todas"
      case params[:offer]
      when "descuento"
        @products = @products.where(:discount.gt => 0, offer_type: "descuento")
      when "2x1"
        @products = @products.where(offer_type: "2x1")
      when "3x1"
        @products = @products.where(offer_type: "3x1")
      when "mayoreo"
        @products = @products.where(offer_type: "mayoreo")
      end
    end

    # ----------------- OFERTAS -----------------
    # Solo para clientes que aún no aceptan notificaciones
    if @current_user&.role&.name == 'cliente' && !@current_user.allow_notifications
      @offer_products = @products.select(&:on_offer?)
      @show_notification_toast = true
    else
      @offer_products = []
      @show_notification_toast = false
    end
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
