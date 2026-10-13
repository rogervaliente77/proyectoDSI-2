module Admin
  class OnlineSalesController < ApplicationController
    # O tu filtro de autenticación de admin
    layout 'dashboard'

    def index
      # Filtramos únicamente las ventas hechas en línea ordenadas de la más reciente a la más antigua
      @online_sales = Sale.where(online_order: true).order_by(created_at: :desc)
    end

    def update_status
      @sale = Sale.find(params[:id])
      new_status = params[:new_status]

      # Lógica de cambio de estado y pago si es aprobado
      payment_update = (new_status == 'confirmed' && @sale.forma_pago == 'transfer') ? 'paid' : @sale.payment_status

      if @sale.update_status_with_log(new_status, current_user.id, "Estado actualizado por administración a: #{new_status}", payment_update)
        redirect_to admin_online_sales_path, notice: "La orden #{@sale.code} fue actualizada correctamente."
      else
        redirect_to admin_online_sales_path, alert: "No se pudo actualizar el estado de la orden."
      end
    end
  end
end