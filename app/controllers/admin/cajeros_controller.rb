module Admin
  class CajerosController < Admin::ApplicationController
    # before_action :set_current_user
    # before_action :check_admin_access
    # before_action :set_product, only: %i[ product_sales edit update destroy]
    layout 'dashboard'
    
    def index
      @cajeros = Cajero.all
    end

    def new
      @cajero = Cajero.new
    end

    def create
      binding.pry
        @cajero = Cajero.new(cajero_params)
      
        if @cajero.save
          redirect_to admin_cajeros_path, notice: "Cajero creado con éxito."
        else
          flash[:alert] = "Hubo un error al crear el cajero"
          render :new, status: :unprocessable_entity
        end
    end

    # def product_sales
    #   @products = @product&.product_sales
    # end

    def edit
      @cajero = Cajero.find(params[:id])
    end

    def update
      @cajero = Cajero.find(params[:id])

      respond_to do |format|
        if @cajero.update(cajero_params)
          format.html {redirect_to admin_cajeros_path, notice: "Cajero actualizado con éxito" }
        else
          format.html { redirect_to admin_cajeros_path, alert: "Ocurrio un error" }
        end
      end
    end

    # def mark_as_delivered
    #   @product_sale = ProductSale.find(params[:product_sale_id])
    
    #   if @product_sale.update(was_delivered: !@product_sale.was_delivered, delivered_at: Time.now)
    #     redirect_to admin_product_sales_path(product_id: @product_sale.product.id), notice: "Producto actualizado con éxito.", status: :see_other
    #   else
    #     redirect_to admin_product_sales_path(product_id: @product_sale.product.id), alert: "Hubo un problema al actualizar el producto", status: :see_other
    #   end
    # end
    
    # def destroy
    #   # binding.pry
    #   @product.destroy!
  
    #   respond_to do |format|
    #     format.html { redirect_to admin_productos_path, status: :see_other, notice: "Producto eliminado exitosamente" }
    #     format.json { head :no_content }
    #   end
    # end

    # private

    # def check_admin_access
    #   if current_user.is_admin == false
    #     redirect_to portal_home_path, alert: "No tienes acceso a esta sección"
    #   end
    # end

    # def set_product
    #   @product = Product.find(params[:product_id]) || nil
    # end

    # def set_current_user
    #   @current_user = current_user
    # end

    def cajero_params
      params.require(:cajero).permit(:nombre, :user_id, :caja_id)
    end
  end
end