module Admin
  class ProductsController < ApplicationController
    before_action :set_current_user
    before_action :set_product, only: %i[edit update destroy product_sales]
    layout 'dashboard'

    # LISTADO DE PRODUCTOS
    def index
      @categories = Category.all
      @marcas = Marca.all
      @products = Product.includes(:category, :marca).all
    end

    # NUEVO PRODUCTO
    def new
      @product = Product.new
      @product.product_images.build
    end

    # CREAR PRODUCTO
    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_productos_path, notice: "Producto creado con éxito."
      else
        flash[:alert] = "Hubo un error al crear el producto"
        render :new, status: :unprocessable_entity
      end
    end

    # EDITAR PRODUCTO
    def edit
      @product.product_images.build if @product.product_images.empty?
    end

    # ACTUALIZAR PRODUCTO
    def update
      if @product.update(product_params)
        redirect_to admin_edit_product_path(product_id: @product.id), notice: "Producto actualizado con éxito"
      else
        flash[:alert] = @product.errors.full_messages.join(", ")
        redirect_to admin_edit_product_path(product_id: @product.id)
      end
    end

    # ELIMINAR PRODUCTO
    def destroy
      @product.destroy!
      redirect_to admin_productos_path, notice: "Producto eliminado exitosamente", status: :see_other
    end

    # VENTAS DE UN PRODUCTO
    def product_sales
      @products = @product&.product_sales
    end

    # 🔹 INVENTARIO
    def inventory
      # Inicializamos @products para que nunca sea nil
      @products = Product.all.order(:name)

      # Filtro de búsqueda por código o nombre
      if params[:query].present?
        q = params[:query].strip
        @products = @products.where(
          :code => /#{Regexp.escape(q)}/i
        ).or(Product.where(:name => /#{Regexp.escape(q)}/i))
      end

      # Aquí no filtramos stock bajo directamente,
      # pero en la vista puedes usar product.low_stock? o product.stock_status
      # para mostrar alertas o badges profesionales.
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
