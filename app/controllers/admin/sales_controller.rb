# app/controllers/admin/sales_controller.rb
module Admin
  class SalesController < Admin::ApplicationController
    layout 'dashboard'

     # PD1-42: alerta de devoluciones pendientes
    before_action :check_pending_devoluciones

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
      # Restricción de rol
      if @current_user.role.name == "super_admin" || @current_user.role.name == "admin"
        redirect_to admin_sales_new_path, alert: "Esta acción solo la puede hacer un cajero"
        return
      end

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
                disposition: 'inline'
    end

    # Productos disponibles para devolución
    def available_products
      sale = Sale.find(params[:id])
      products = sale.products_available_for_return.map do |ps|
        {
          id: ps.id,
          name: ps.product.name,
          quantity: ps.quantity,
          price: ps.unit_price - (ps.discount || 0) # precio unitario con descuento
        }
      end

      render json: products
    end

    # Búsqueda de venta por código (para devoluciones)
    def search_by_code
      sale = Sale.where(code: params[:code]).first

      if sale && sale.has_products_available_for_return?
        render json: {
          id: sale.id.to_s,
          client_name: sale.client_name,
          products: sale.products_available_for_return.map do |ps|
            {
              id: ps.product_id.to_s,
              name: ps.product_name,
              quantity: ps.quantity,
              price: ps.unit_price - (ps.discount || 0) # precio unitario con descuento
            }
          end
        }
      else
        render json: { error: "Venta no encontrada o sin productos disponibles" }, status: :not_found
      end
    end

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
    
    # PD1-42: verificar devoluciones pendientes
    def check_pending_devoluciones
      if current_user && current_user.role && ["admin", "super_admin"].include?(current_user.role.name)
        @pending_devoluciones_count = Devolucion.where(is_authorized: false).count
      else
        @pending_devoluciones_count = 0
      end
    end

  end
end
