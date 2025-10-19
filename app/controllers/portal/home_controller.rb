module Portal
  class HomeController < ApplicationController
    layout 'dashboard'
    before_action :set_current_user

    def index
      @products = Product.all.includes(:category, :marca)
      @categories = Category.all
      @marcas = Marca.all

      # Filtros
      @products = @products.where(name: /#{Regexp.escape(params[:query])}/i) if params[:query].present?
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
      @products = @products.where(marca_id: params[:marca_id]) if params[:marca_id].present?
      @products = @products.where(:price.gte => params[:min_price].to_f) if params[:min_price].present?
      @products = @products.where(:price.lte => params[:max_price].to_f) if params[:max_price].present?

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
      # Solo mostrar notificaciones la primera vez que inicia sesión
      if @current_user&.role&.name == 'cliente' && !@current_user.allow_notifications
        @offer_products = @products.select(&:on_offer?)
        # Marcamos que ya se mostraron las notificaciones
        @current_user.update(allow_notifications: true)
      else
        @offer_products = []
      end
    end

    private

    def set_current_user
      @current_user = current_user
    end
  end
end
