module Admin
  class DeliveryDriversController < Admin::ApplicationController
    before_action :set_current_user
    # before_action :check_admin_access
    # before_action :set_product, only: %i[ product_sales edit update destroy]
    layout 'dashboard'
    
    def index
      @delivery_drivers = DeliveryDriver.all
    end

    def new
      @delivery_driver = DeliveryDriver.new
    end

    def create
        @delivery_driver = DeliveryDriver.new(delivery_driver_params)
      
        if @delivery_driver.save
          redirect_to admin_delivery_drivers_path, notice: "Mensajero creado con éxito."
        else
          flash[:alert] = "Hubo un error al crear el mensajero"
          render :new, status: :unprocessable_entity
        end
    end

    # def product_sales
    #   @products = @product&.product_sales
    # end

    def edit
      @delivery_driver = DeliveryDriver.find(params[:id])
    end

    def update
      @delivery_driver = DeliveryDriver.find(params[:id])

      respond_to do |format|
        if @delivery_driver.update(delivery_driver_params)
          format.html {redirect_to admin_delivery_drivers_path, notice: "Mensajero actualizado con éxito" }
        else
          format.html { redirect_to admin_delivery_drivers_path, alert: "Ocurrio un error" }
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

    def set_current_user
      @current_user = current_user
    end

    def delivery_driver_params
      params.require(:delivery_driver).permit(:nombre, :user_id, :transportation_type)
    end
  end
end