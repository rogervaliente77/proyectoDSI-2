module Admin
  class SupplierPaymentsController < ApplicationController
    def create
      @invoice = SupplierInvoice.find(params[:supplier_invoice_id])
      @payment = @invoice.supplier_payments.build(payment_params)

      if @invoice.save
        redirect_to admin_supplier_invoice_path(@invoice), notice: "Abono de $#{sprintf('%.2f', @payment.amount)} registrado exitosamente."
      else
        redirect_to admin_supplier_invoice_path(@invoice), alert: "Error al registrar el abono. Verifica los datos."
      end
    end

    def destroy
      @invoice = SupplierInvoice.find(params[:supplier_invoice_id])
      payment = @invoice.supplier_payments.find(params[:id])
      
      payment.destroy
      @invoice.save # Dispara el callback para recalcular el saldo
      redirect_to admin_supplier_invoice_path(@invoice), notice: "Abono eliminado y saldo recalculado."
    end

    private

    def payment_params
      params.require(:supplier_payment).permit(:amount, :payment_date, :payment_method, :reference_number, :notes)
    end
  end
end