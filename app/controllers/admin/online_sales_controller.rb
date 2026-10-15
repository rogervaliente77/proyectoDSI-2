module Admin
  class OnlineSalesController < ApplicationController
    layout 'dashboard'

    def index
      @online_sales = Sale.where(online_order: true).order_by(created_at: :desc)
    end

    # Acción para apagar el timbre persistente de nueva venta
    def acknowledge
      @sale = Sale.find(params[:id])
      @sale.update(admin_acknowledged: true)
      render json: { success: true }
    end

    def update_status
      @sale = Sale.find(params[:id])
      new_status = params[:new_status]
    
      # Determinamos reglas de pago según el nuevo estatus
      payment_update = @sale.payment_status
      if ['payment_approved', 'paid', 'delivered'].include?(new_status) && @sale.forma_pago == 'TRANSFERENCIA'
        payment_update = 'paid'
      elsif new_status == 'delivered' && @sale.forma_pago != 'TRANSFERENCIA'
        payment_update = 'paid' # Contra entrega pagada al entregar
      end
    
      comment = "Estado actualizado a: #{new_status.titleize}"
    
      if @sale.update_status_with_log(new_status, current_user.id, comment, payment_update)
        ActionCable.server.broadcast("admin_online_sales", { 
          action: "update_status", 
          sale_id: @sale.id.to_s, 
          code: @sale.code,
          status: @sale.status,
          payment_status: @sale.payment_status
        })
    
        redirect_to admin_online_sales_path, notice: "La orden #{@sale.code} fue actualizada correctamente."
      else
        redirect_to admin_online_sales_path, alert: "No se pudo actualizar el estado de la orden."
      end
    end
  end
end