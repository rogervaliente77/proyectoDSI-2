module Admin
  class SupplierInvoicesController < ApplicationController
    before_action :set_invoice, only: [:show, :edit, :update, :destroy]
    layout 'dashboard'

    def index
      # 1. Proveedores para selectores/filtros en la vista
      @suppliers = Supplier.where(active: true).order_by(name: :asc)

      # 2. Construcción del scope con filtros dinámicos
      scope = SupplierInvoice.all

      if params[:query].present?
        q_regex = /#{Regexp.escape(params[:query].strip)}/i
        scope = scope.any_of({ invoice_number: q_regex }, { voucher_number: q_regex })
      end

      scope = scope.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
      scope = scope.where(status: params[:status]) if params[:status].present?

      if params[:start_date].present? && params[:end_date].present?
        s_date = Date.parse(params[:start_date]) rescue nil
        e_date = Date.parse(params[:end_date]) rescue nil
        scope = scope.where(:issue_date.gte => s_date, :issue_date.lte => e_date) if s_date && e_date
      end

      # 3. Rangos de fechas para métricas globales
      today = Date.today
      bom   = today.beginning_of_month.to_time.utc
      eom   = today.end_of_month.to_time.utc

      # 4. Agregación consolidada (4 cálculos en 1 sola consulta a MongoDB)
      metrics = SupplierInvoice.collection.aggregate([
        {
          '$facet' => {
            'total_debt' => [
              { '$match' => { 'status' => { '$in' => %w[pendiente vencida] }, 'balance' => { '$exists' => true } } },
              { '$group' => { '_id' => nil, 'total' => { '$sum' => '$balance' } } }
            ],
            'overdue_debt' => [
              { '$match' => { 'status' => 'vencida', 'balance' => { '$exists' => true } } },
              { '$group' => { '_id' => nil, 'total' => { '$sum' => '$balance' } } }
            ],
            'due_this_month' => [
              { '$match' => { 'status' => { '$in' => %w[pendiente vencida] }, 'due_date' => { '$gte' => bom, '$lte' => eom }, 'balance' => { '$exists' => true } } },
              { '$group' => { '_id' => nil, 'total' => { '$sum' => '$balance' } } }
            ],
            'total_paid_month' => [
              { '$match' => { 'payment_date' => { '$gte' => bom, '$lte' => eom }, 'paid_amount' => { '$exists' => true } } },
              { '$group' => { '_id' => nil, 'total' => { '$sum' => '$paid_amount' } } }
            ]
          }
        }
      ]).first || {}

      # Mapeo a las variables de instancia que consume tu vista
      @stats_total_debt       = metrics.dig('total_debt', 0, 'total') || 0.0
      @stats_overdue_debt     = metrics.dig('overdue_debt', 0, 'total') || 0.0
      @stats_due_this_month   = metrics.dig('due_this_month', 0, 'total') || 0.0
      @stats_total_paid_month = metrics.dig('total_paid_month', 0, 'total') || 0.0

      # 5. Paginación y precarga de asociaciones
      @invoices = scope.includes(:supplier)
                       .order_by(due_date: :asc)
                       .page(params[:page])
                       .per(3)

      # Conteo guardado en variable para evitar consultas duplicadas
      @total_invoices = @invoices.total_count
    end

    def show
      @invoice = SupplierInvoice.includes(:supplier).find(params[:id])
      
      # 1. Obtenemos solo los pagos que ya están persistidos en la base de datos
      @payments = @invoice.supplier_payments.select(&:persisted?)

      # 2. Instanciamos el objeto para el formulario sin vincularlo a @invoice
      @payment = SupplierPayment.new(
        payment_date: Date.today,
        amount: @invoice.balance
      )
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