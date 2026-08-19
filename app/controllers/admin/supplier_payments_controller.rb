# app/controllers/admin/supplier_payments_controller.rb
module Admin
  class SupplierPaymentsController < ApplicationController
    before_action :set_supplier_invoice, :set_current_user

    def create
      # 1. Se construye el subdocumento en el arreglo supplier_payments de la factura
      @payment = @supplier_invoice.supplier_payments.build(supplier_payment_params)
      
      # 2. Asignamos el BSON::ObjectId directamente a created_by
      @payment.created_by = current_user.id # o @current_user.id

      # 3. Guardamos el documento PADRE (@supplier_invoice)
      if @supplier_invoice.save
        redirect_to admin_supplier_invoice_path(@supplier_invoice), notice: "Pago registrado exitosamente."
      else
        Rails.logger.error "Errores al guardar el pago: #{@supplier_invoice.errors.full_messages.join(', ')}"

        redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                    alert: "No se pudo registrar el pago: #{@supplier_invoice.errors.full_messages.to_sentence}",
                    status: :see_other
      end
    end

    def destroy
      @payment = @supplier_invoice.supplier_payments.find(params[:id])
      @payment.destroy
      redirect_to admin_supplier_invoice_path(@supplier_invoice), 
                  notice: "El pago fue eliminado y el saldo de la factura ha sido recalculado."
    end

    private

    def set_supplier_invoice
      @supplier_invoice = SupplierInvoice.find(params[:supplier_invoice_id])
    end

    def set_current_user
      @current_user = current_user
    end

    def supplier_payment_params
      params.require(:supplier_payment).permit(:amount, :payment_date, :payment_method, :reference_number, :notes)
    end
  end
end