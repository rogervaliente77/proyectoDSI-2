module Admin
  class ProductsController < ApplicationController
    before_action :set_current_user
    before_action :set_product, only: %i[edit update destroy product_sales]
    layout 'dashboard'

    def index
      @categories = Category.all
      @marcas = Marca.all
      @products = Product.includes(:category, :marca).all

      # Filtrar por nombre
      if params[:query].present?
        q = params[:query].strip
        @products = @products.where(name: /#{Regexp.escape(q)}/i)
      end

      # Filtrar por categoría
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?

      # Filtrar por marca
      @products = @products.where(marca_id: params[:marca_id]) if params[:marca_id].present?

      # Filtrar por rango de precio
      min_price = params[:min_price].present? ? params[:min_price].to_f : 0
      max_price = params[:max_price].present? ? params[:max_price].to_f : Float::INFINITY
      @products = @products.where(:price.gte => min_price, :price.lte => max_price)
    end

    def new
      @product = Product.new
      @product.product_images.build
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_productos_path, notice: "Producto creado con éxito."
      else
        flash[:alert] = "Hubo un error al crear el producto"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @product.product_images.build if @product.product_images.empty?
    end

    def update
      if @product.update(product_params)
        redirect_to admin_edit_product_path(product_id: @product.id), notice: "Producto actualizado con éxito"
      else
        flash[:alert] = @product.errors.full_messages.join(", ")
        redirect_to admin_edit_product_path(product_id: @product.id)
      end
    end

    def destroy
      @product.destroy!
      redirect_to admin_productos_path, notice: "Producto eliminado exitosamente", status: :see_other
    end

    def product_sales
      @products = @product&.product_sales
    end

    # 🔹 Acción INVENTARIO
    def inventory
      @products = Product.all.includes(:category, :marca).asc(:name)

      if params[:query].present?
        q = params[:query].strip
        @products = @products.any_of({ name: /#{Regexp.escape(q)}/i }, { code: /#{Regexp.escape(q)}/i })
      end
    end

    def search
      query = params[:q].to_s.strip
      products = Product.where(name: /#{Regexp.escape(query)}/i).limit(10)
      render json: products.map { |p| { id: p.id.to_s, name: p.name, description: p.description, price: p.price, discount: p.discount } }
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_current_user
      @current_user = current_user
    end

    def product_params
      params.require(:product).permit(
        :name, :description, :quantity, :price, :category_id, :marca_id, :discount,
        product_images_attributes: [:id, :title, :image_url, :image_index, :_destroy]
      )
    end
  end
end
