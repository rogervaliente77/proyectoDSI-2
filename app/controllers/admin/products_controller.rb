# app/controllers/admin/products_controller.rb
module Admin
  class ProductsController < ApplicationController
    before_action :set_current_user
    before_action :set_product, only: %i[edit update destroy product_sales]
    layout 'dashboard'

    def index
      @products = Product.all
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

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_current_user
      @current_user = current_user
    end

    def product_params
      params.require(:product).permit(
        :name, :description, :quantity, :price, :category_id,
        product_images_attributes: [:id, :title, :image_url, :image_index, :_destroy]
      )
    end
  end
end
