module Portal
  class HomeController < ApplicationController
    layout 'dashboard'
    # before_action :authenticate_user!

    def index
      @current_user = current_user

      # Traer todos los productos, categorías y marcas
      @products = Product.all
      @categories = Category.all
      @marcas = Marca.all

      # Filtros
      @products = @products.where(name: /#{Regexp.escape(params[:query])}/i) if params[:query].present?
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
      @products = @products.where(marca_id: params[:marca_id]) if params[:marca_id].present?
      @products = @products.where(:price.gte => params[:min_price].to_f) if params[:min_price].present?
      @products = @products.where(:price.lte => params[:max_price].to_f) if params[:max_price].present?
    end
  end
end
