module Admin
  class ProductsController < ApplicationController
    before_action :set_current_user
    before_action :set_product, only: %i[edit update destroy product_sales]
    layout 'dashboard'

    def index
      @categories = Category.all
      @marcas = Marca.all
      @products = Product.includes(:category, :marca).all

      # Filtros de búsqueda
      @products = @products.where(name: /#{Regexp.escape(params[:query].strip)}/i) if params[:query].present?
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
      @products = @products.where(marca_id: params[:marca_id]) if params[:marca_id].present?

      min_price = params[:min_price].present? ? params[:min_price].to_f : 0
      max_price = params[:max_price].present? ? params[:max_price].to_f : Float::INFINITY
      @products = @products.where(:price.gte => min_price, :price.lte => max_price)

      # Filtro por tipo de oferta
      if params[:offer].present? && params[:offer] != "todas"
        case params[:offer]
        when "descuento"
          @products = @products.where(:discount.gt => 0)
        when "2x1", "mayoreo"
          @products = @products.where(:offer_type.in => ["2x1", "mayoreo"])
        end
      end

      # Ordenar por nombre
      @products = @products.asc(:name)
    end

    def new
      @product = Product.new
      @product.product_images.build
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        create_product_history(@product, 0, @product.quantity, "Ingreso inicial")
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
      stock_before = @product.quantity
      if @product.update(product_params)
        if product_params[:quantity].to_i != stock_before
          movement_type = product_params[:quantity].to_i > stock_before ? "Ingreso" : "Salida"
          create_product_history(@product, stock_before, @product.quantity, movement_type)
        end
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

    def inventory
      @products = Product.all.includes(:category, :marca).asc(:name)
      if params[:query].present?
        @products = @products.any_of(
          { name: /#{Regexp.escape(params[:query].strip)}/i },
          { code: /#{Regexp.escape(params[:query].strip)}/i }
        )
      end
    end

    def search
      query = params[:q].to_s.strip
      products = Product.where(name: /#{Regexp.escape(query)}/i).limit(10)
      render json: products.map { |p| 
        { 
          id: p.id.to_s, 
          name: p.name, 
          description: p.description, 
          price: p.price, 
          discount: p.discount,
          offer_type: p.offer_type,
          offer_expires_at: p.offer_expires_at
        } 
      }
    end

    def devueltos
      @returned_products = ReturnedProduct.all
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_current_user
      @current_user = current_user
    end

    # Permitir nuevos campos de ofertas
    def product_params
      params.require(:product).permit(
        :name, :description, :quantity, :price, :category_id, :marca_id, :discount, :code,
        :offer_type, :offer_expires_at, :wholesale_quantity,
        product_images_attributes: [:id, :title, :image_url, :image_index, :_destroy]
      )
    end

    # Crear historial de producto
    def create_product_history(product, stock_before, stock_after, movement_type)
      ProductHistory.create!(
        product: product,
        name: product.name,
        description: product.description,
        code: product.code,
        quantity: (stock_after - stock_before).abs,
        price: product.price,
        discount: product.discount,
        stock_before: stock_before,
        current_stock: stock_after,
        movement_type: movement_type,
        user_id: @current_user.id
      )
    end
  end
end
