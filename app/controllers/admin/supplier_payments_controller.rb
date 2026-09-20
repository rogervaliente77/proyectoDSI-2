module Admin
  class SupplierPaymentsController < ApplicationController
    before_action :set_supplier_invoice

    def create
      @payment = @supplier_invoice.supplier_payments.build(payment_params)

      if @payment.save
        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    notice: "El pago fue registrado correctamente."
      else
        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    alert: "No se pudo registrar el pago. Verifique los datos ingresados."
      end
    end

    def destroy
      # Convertir la cadena de params[:id] a un objeto BSON::ObjectId para Mongoid
      payment_id = BSON::ObjectId.from_string(params[:id]) rescue nil

      # Buscar el subdocumento embebido dentro del arreglo
      @payment = @supplier_invoice.supplier_payments.where(_id: payment_id).first if payment_id

      if @payment
        @payment.destroy
        @supplier_invoice.save! # Recalcula automáticamente el saldo y estados

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
        :notes
      )
    end
  end
end