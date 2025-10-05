module Admin
  class SalesController < Admin::ApplicationController
    # before_action :set_current_user
    # before_action :check_admin_access
    # before_action :set_product, only: %i[ product_sales edit update destroy]
    layout 'dashboard'
    
    def index
      @sales = Sale.all
    
      # Filtro por código
      if params[:code].present?
        @sales = @sales.where(code: /#{Regexp.escape(params[:code])}/i)
      end
    
      # Filtro por rango de fecha
      if params[:start_date].present? && params[:end_date].present?
        start_date = DateTime.parse(params[:start_date]).beginning_of_day
        end_date   = DateTime.parse(params[:end_date]).end_of_day
        @sales = @sales.where(:sold_at.gte => start_date, :sold_at.lte => end_date)
      end
    
      # Ordenar por fecha descendente
      @sales = @sales.order_by(sold_at: :desc)
    end

    def new
      @sale = Sale.new
    end

    def create
      # Restricción de rol (ya lo tenés)
      if @current_user.role.name == "super_admin" || @current_user.role.name == "admin"
        redirect_to admin_sales_new_path, alert: "Esta acción solo la puede hacer un cajero"
        return
      end

      # Crear la venta con nested attributes
      @sale = Sale.new(sale_params)
      @sale.status = "confirmed"
      @sale.sold_at = Time.now
      if @sale.save
        redirect_to admin_sales_path, notice: "Venta registrada correctamente"
      else
        flash.now[:alert] = "Error al registrar la venta"
        render :new
      end
    end

    def detalle_venta
      @sale = Sale.find(params[:id])
      @product_sales = @sale.product_sales
    end

    def generate_pdf
      @sale = Sale.find(params[:id])
    
      pdf = SalePdf.new(@sale).generate
    
      send_data pdf,
                filename: "venta_#{@sale.code}.pdf",
                type: 'application/pdf',
                disposition: 'inline'  # Cambia a 'attachment' si querés forzar descarga
    end

    # Acción para devolver productos disponibles para devolución
    def available_products
      sale = Sale.find(params[:id])
      products = sale.products_available_for_return.map do |ps|
        { id: ps.id, name: ps.product.name, quantity: ps.quantity }
      end

      render json: products
    end

    
    # def product_sales
    #   @products = @product&.product_sales
    # end

    # def edit
    #   # binding.pry
    # end

    # def update
    #   respond_to do |format|
    #     if @product.update(product_params)
    #       format.html {redirect_to admin_edit_product_path(product_id: @product.id), notice: "Producto actualizado con éxito" }
    #     else
    #       format.html { redirect_to admin_edit_product_path(product_id: @product.id), alert: "Ocurrio un error" }
    #     end
    #   end
    # end

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

    private

    def sale_params
      params.require(:sale).permit(
        :client_name,
        :cajero_id,
        :caja_id,
        :total_amount,
        product_sales_attributes: [:product_id, :quantity, :unit_price, :discount]
      )
    end

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

    # def product_params
    #   params.require(:product).permit(:name, :description, :quantity, :price, :image_url)
    # end
  end
end
