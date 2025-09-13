# app/controllers/portal/home_controller.rb
module Portal
  class HomeController < ApplicationController
    layout 'dashboard'
    # before_action :authenticate_user!  # Descomenta si quieres solo clientes logueados

    def index
      # Usuario actual
      @current_user = current_user

      # Todas las categorías para el select de filtros
      @categories = Category.all

      # Todos los productos, pre-cargando categoría
      @products = Product.includes(:category).all

      # Filtro por nombre usando regex
      if params[:query].present?
        regex = /#{Regexp.escape(params[:query])}/i
        @products = @products.where(name: regex)
      end

      # Filtro por categoría
      if params[:category_id].present? && params[:category_id] != ""
        @products = @products.where(category_id: params[:category_id])
      end

      # Filtro por precio mínimo y máximo
      min_price = params[:min_price].present? ? params[:min_price].to_f : nil
      max_price = params[:max_price].present? ? params[:max_price].to_f : nil

      if min_price && max_price
        @products = @products.where(:price.gte => min_price, :price.lte => max_price)
      elsif min_price
        @products = @products.where(:price.gte => min_price)
      elsif max_price
        @products = @products.where(:price.lte => max_price)
      end
    end
  end
end
