module Admin
  class SuppliersController < ApplicationController
    before_action :set_supplier, only: [:show, :edit, :update, :destroy]
    layout 'dashboard'

    def index
      @suppliers = Supplier.all
      
      if params[:query].present?
        query_regex = /#{Regexp.escape(params[:query])}/i
        @suppliers = @suppliers.any_of({ name: query_regex }, { nit_nrc: query_regex }, { phone: query_regex })
      end

      # Paginación (Páginas de 10)
      @suppliers = @suppliers.order_by(name: :asc).page(params[:page]).per(10)
    end

    def show
      # Facturas asociadas para la vista show con paginación
      @invoices = @supplier.supplier_invoices.order_by(due_date: :asc).page(params[:page]).per(10)
      
      # Estadísticas individuales del proveedor
      @total_invoiced = @supplier.supplier_invoices.sum(:total_amount) || 0.0
      @total_paid = @supplier.supplier_invoices.sum(:paid_amount) || 0.0
      @total_pending = @supplier.supplier_invoices.where(:status.in => ["pendiente", "vencida"]).sum(:balance) || 0.0
      @overdue_count = @supplier.supplier_invoices.where(status: "vencida").count
    end

    def new
      @supplier = Supplier.new
    end

    def create
      @supplier = Supplier.new(supplier_params)
      if @supplier.save
        redirect_to admin_suppliers_path, notice: "Proveedor creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @supplier.update(supplier_params)
        redirect_to admin_supplier_path(@supplier), notice: "Proveedor actualizado correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @supplier.destroy
        redirect_to admin_suppliers_path, notice: "Proveedor eliminado."
      else
        redirect_to admin_suppliers_path, alert: "No se puede eliminar un proveedor con facturas registradas."
      end
    end

    private

    def set_supplier
      @supplier = Supplier.find(params[:id])
    end

    def supplier_params
      params.require(:supplier).permit(:name, :business_name, :nit_nrc, :phone, :email, :address, :contact_person, :credit_days, :credit_limit, :active)
    end
  end
end