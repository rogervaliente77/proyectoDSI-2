module Admin
  class SupplierPaymentsController < ApplicationController
    before_action :set_supplier_invoice

    def create
      # Buscar perfil de cajero asociado al usuario actual
      cajero_actual = Cajero.find_by(user_id: current_user.id) if current_user.respond_to?(:puede_vender?) && current_user.puede_vender?

      unless cajero_actual
        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    alert: "No se puede registrar el pago: El usuario actual no está configurado como cajero."
        return
      end

      @payment = @supplier_invoice.supplier_payments.build(payment_params)
      
      # Asignación automática de auditoría y caja
      @payment.created_by = current_user.id
      @payment.cajero_id  = cajero_actual.id
      @payment.caja_id    = cajero_actual.caja_id
      @payment.sucursal_id = cajero_actual.caja&.sucursal_id

      if @payment.save
        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    notice: "El pago fue registrado correctamente."
      else
        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    alert: "No se pudo registrar el pago. Verifique los datos ingresados."
      end
    end

    def destroy
      payment_id = BSON::ObjectId.from_string(params[:id]) rescue nil
      @payment = @supplier_invoice.supplier_payments.where(_id: payment_id).first if payment_id

      if @payment
        @payment.destroy
        @supplier_invoice.save!

        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    notice: "El pago fue eliminado y el saldo de la factura ha sido recalculado."
      else
        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    alert: "No se encontró el registro del pago a eliminar."
      end
    end

    private

    def set_supplier_invoice
      @supplier_invoice = SupplierInvoice.find(params[:supplier_invoice_id])
    end

    def payment_params
      params.require(:supplier_payment).permit(
        :amount, 
        :payment_date, 
        :payment_method, 
        :reference_number, 
        :notes,
        :sucursal_id,
        :caja_id,
        :cajero_id
      )
    end
  end
end