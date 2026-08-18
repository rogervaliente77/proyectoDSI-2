module Admin
  class SupplierInvoicesController < ApplicationController
    before_action :set_invoice, only: [:show, :edit, :update, :destroy]
    layout 'dashboard'

    def index
      @suppliers = Supplier.where(active: true).order_by(name: :asc)
      @invoices = SupplierInvoice.all

      # --- FILTROS ---
      if params[:query].present?
        q_regex = /#{Regexp.escape(params[:query])}/i
        @invoices = @invoices.any_of({ invoice_number: q_regex }, { voucher_number: q_regex })
      end

      if params[:supplier_id].present?
        @invoices = @invoices.where(supplier_id: params[:supplier_id])
      end

      if params[:status].present?
        @invoices = @invoices.where(status: params[:status])
      end

      if params[:start_date].present? && params[:end_date].present?
        s_date = Date.parse(params[:start_date]) rescue nil
        e_date = Date.parse(params[:end_date]) rescue nil
        @invoices = @invoices.where(:issue_date.gte => s_date, :issue_date.lte => e_date) if s_date && e_date
      end

      # --- ESTADÍSTICAS GLOBALES PARA LAS CARDS SUPERIORES ---
      all_pending = SupplierInvoice.where(:status.in => ["pendiente", "vencida"])
      @stats_total_debt = all_pending.sum(:balance) || 0.0
      @stats_overdue_debt = SupplierInvoice.where(status: "vencida").sum(:balance) || 0.0
      @stats_due_this_month = all_pending.where(:due_date.gte => Date.today.beginning_of_month, :due_date.lte => Date.today.end_of_month).sum(:balance) || 0.0
      @stats_total_paid_month = SupplierInvoice.where(:payment_date.gte => Date.today.beginning_of_month, :payment_date.lte => Date.today.end_of_month).sum(:paid_amount) || 0.0

      # --- PAGINACIÓN ---
      @invoices = @invoices.order_by(due_date: :asc).page(params[:page]).per(10)
    end

    def show
      @payment = SupplierPayment.new
    end

    def new
      @invoice = SupplierInvoice.new
      @suppliers = Supplier.where(active: true)
    end

    def create
      @invoice = SupplierInvoice.new(invoice_params)
      if @invoice.save
        redirect_to admin_supplier_invoice_path(@invoice), notice: "Factura de proveedor registrada correctamente."
      else
        @suppliers = Supplier.where(active: true)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @suppliers = Supplier.where(active: true)
    end

    def update
      if @invoice.update(invoice_params)
        redirect_to admin_supplier_invoice_path(@invoice), notice: "Factura actualizada."
      else
        @suppliers = Supplier.where(active: true)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @invoice.destroy
      redirect_to admin_supplier_invoices_path, notice: "Factura eliminada con éxito."
    end

    private

    def set_invoice
      @invoice = SupplierInvoice.find(params[:id])
    end

    def invoice_params
      params.require(:supplier_invoice).permit(:supplier_id, :invoice_number, :voucher_number, :voucher_type, :description, :issue_date, :due_date, :total_amount)
    end
  end
end