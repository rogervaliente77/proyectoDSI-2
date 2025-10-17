module Portal
  class HomeController < ApplicationController
    layout 'dashboard'
    before_action :set_current_user

    def index
      # Traer todos los productos, categorías y marcas
      @products = Product.all.includes(:category, :marca)
      @categories = Category.all
      @marcas = Marca.all

      # Filtros
      @products = @products.where(name: /#{Regexp.escape(params[:query])}/i) if params[:query].present?
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
      @products = @products.where(marca_id: params[:marca_id]) if params[:marca_id].present?
      @products = @products.where(:price.gte => params[:min_price].to_f) if params[:min_price].present?
      @products = @products.where(:price.lte => params[:max_price].to_f) if params[:max_price].present?

      # ----------------- OFERTAS -----------------
      if @current_user&.role&.name == 'cliente' && !@current_user.allow_notifications
        # Solo productos con descuento u oferta vigente
        @offer_products = @products.select(&:on_offer?)
      else
        @offer_products = []
      end
    end

    # ----------------- NUEVO MÉTODO -----------------
    def accept_notifications
      if @current_user
        @current_user.update(allow_notifications: true)
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
end
