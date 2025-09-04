class LandingController < ApplicationController
  def index
    # Traer todas las categorías para el filtro
    @categories = Category.all

    # Iniciamos con todos los productos
    @products = Product.includes(:category).all

    # Filtrar por nombre
    if params[:query].present?
      regex = /#{Regexp.escape(params[:query])}/i
      @products = @products.where(name: regex)
    end

    # Filtrar por categoría
    if params[:category_id].present? && params[:category_id] != ""
      @products = @products.where(category_id: params[:category_id])
    end

    # Filtrar por precio mínimo y máximo
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
