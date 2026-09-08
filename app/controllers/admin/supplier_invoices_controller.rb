module Admin
  class SupplierInvoicesController < ApplicationController
    before_action :set_invoice, only: [:show, :edit, :update, :destroy]
    layout 'dashboard'

    def index
      @suppliers = Supplier.where(active: true).order_by(name: :asc)
      scope = SupplierInvoice.all

      if params[:query].present?
        q_regex = /#{Regexp.escape(params[:query].strip)}/i
        scope = scope.any_of({ invoice_number: q_regex }, { voucher_number: q_regex })
      end

      scope = scope.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?

      if params[:start_date].present? && params[:end_date].present?
        s_date = Date.parse(params[:start_date]) rescue nil
        e_date = Date.parse(params[:end_date]) rescue nil
        scope = scope.where(:issue_date.gte => s_date, :issue_date.lte => e_date) if s_date && e_date
      end

      all_invoices = scope.order_by(due_date: :asc).to_a

      # Filtrar por estado dinámico si viene el parámetro
      if params[:status].present?
        all_invoices.select! { |inv| inv.status == params[:status] }
      end

      # Métricas dinámicas calculadas en vivo
      today = Date.today
      bom   = today.beginning_of_month
      eom   = today.end_of_month

      @stats_total_debt       = all_invoices.select { |i| i.balance > 0 }.sum(&:balance)
      @stats_overdue_debt     = all_invoices.select { |i| i.status == "vencida" }.sum(&:balance)
      @stats_due_this_month   = all_invoices.select { |i| i.due_date.present? && i.due_date.between?(bom, eom) && i.balance > 0 }.sum(&:balance)
      @stats_total_paid_month = all_invoices.sum { |i| i.supplier_payments.select { |p| p.payment_date&.between?(bom, eom) }.sum(&:amount) }

      # Paginación manual con Kaminari sobre Array
      @invoices = Kaminari.paginate_array(all_invoices).page(params[:page]).per(10)
      @total_invoices = all_invoices.size
    end


    def show
      @invoice = SupplierInvoice.includes(:supplier).find(params[:id])
      @payments = @invoice.supplier_payments.select(&:persisted?)
      @installments = @invoice.payment_installments.order_by(number: :asc)
      @status_histories = @invoice.status_histories.order_by(changed_at: :desc)

      @payment = SupplierPayment.new(
        payment_date: Date.today,
        amount: @invoice.balance
      )
    end

    def new
      @invoice = SupplierInvoice.new(
        is_credit: true, 
        installments_count: 1, 
        credit_term_days: 30,
        term_type: "mensual"
      )
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

    def history
      @invoice = SupplierInvoice.find(params[:id])
      @history = @invoice.status_histories.order_by(created_at: :desc)
      render layout: false
    end

    private

    def set_invoice
      @invoice = SupplierInvoice.find(params[:id])
    end

    def invoice_params
      params.require(:supplier_invoice).permit(
        :supplier_id, :invoice_number, :voucher_number, :voucher_type,
        :description, :issue_date, :due_date, :payment_date, :total_amount,
        :is_credit, :credit_term_days, :installments_count, :interest_rate,
        :term_type, :payment_day
      )
    end
  end
end