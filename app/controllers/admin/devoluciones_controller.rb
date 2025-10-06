# app/controllers/admin/devoluciones_controller.rb
module Admin
  class DevolucionesController < ApplicationController
    before_action :set_devolucion, only: %i[edit update destroy]
    layout 'dashboard'

    # Listado de devoluciones con filtros por fecha
    def index
      @devoluciones = Devolucion.all.order_by(created_at: :desc)

      #  Filtro por rango de fechas
      if params[:start_date].present? && params[:end_date].present?
        start_date = DateTime.parse(params[:start_date]).beginning_of_day
        end_date   = DateTime.parse(params[:end_date]).end_of_day
        @devoluciones = @devoluciones.where(:fecha_devolucion.gte => start_date, :fecha_devolucion.lte => end_date)
      end
    end

    #  Nueva acción: generar reporte PDF de devoluciones
    def generate_report
      start_date = params[:start_date].present? ? DateTime.parse(params[:start_date]).beginning_of_day : nil
      end_date   = params[:end_date].present? ? DateTime.parse(params[:end_date]).end_of_day : nil

      devoluciones = Devolucion.all
      devoluciones = devoluciones.where(:fecha_devolucion.gte => start_date, :fecha_devolucion.lte => end_date) if start_date && end_date

      pdf = DevolucionesReportPdf.new(devoluciones, start_date, end_date).generate

      send_data pdf,
                filename: "reporte_devoluciones_#{Time.now.strftime('%Y%m%d')}.pdf",
                type: "application/pdf",
                disposition: "inline"
    end

# Nueva acción: generar PDF de un comprobante individual
    def generate_pdf
      @devolucion = Devolucion.find(params[:id])
      pdf = DevolucionPdf.new(@devolucion).generate

      send_data pdf,
                filename: "devolucion_#{@devolucion.id}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    end
    
    def new
      @devolucion = Devolucion.new
    end

    def create
      @devolucion = Devolucion.new(devolucion_params)
      @devolucion.calcular_total
      if @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolución creada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @devolucion.update(devolucion_params)
        @devolucion.calcular_total
        @devolucion.save
        redirect_to admin_devoluciones_path, notice: "Devolución actualizada con éxito."
      else
        flash[:alert] = @devolucion.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @devolucion.destroy
        redirect_to admin_devoluciones_path, notice: "Devolución eliminada exitosamente", status: :see_other
      else
        redirect_to admin_devoluciones_path, alert: "No se pudo eliminar la devolución", status: :unprocessable_entity
      end
    end

    # Autorizar/desautorizar devolución y generar ReturnedProduct
    def autorizar_devolucion
      @devolucion = Devolucion.find(params[:id])

      if !@devolucion.is_authorized
        @devolucion.authorized_at = Time.current

        @devolucion.sale_devolucion_detalle.each do |detalle|
          next if detalle["cantidad"].to_f <= 0
          begin
            product = Product.find(BSON::ObjectId.from_string(detalle["product_id"]))
          rescue Mongoid::Errors::DocumentNotFound
            next
          end

          ReturnedProduct.create!(
            product: product,
            sale: @devolucion.sale,
            devolucion: @devolucion,
            quantity: detalle["cantidad"].to_i,
            unit_price: detalle["precio_unitario"].to_f,
            discount: 0,
            returned_at: Time.current
          )
        end
      else
        @devolucion.authorized_at = nil
      end

      @devolucion.update(is_authorized: !@devolucion.is_authorized, authorized_at: @devolucion.authorized_at)
      redirect_to admin_devoluciones_path, notice: "Devolución actualizada exitosamente", status: :see_other
    end

    private

    def set_devolucion
      @devolucion = Devolucion.find(params[:id])
      redirect_to admin_devoluciones_path, alert: "Devolución no encontrada" unless @devolucion
    end

    def devolucion_params
      params.require(:devolucion).permit(
        :client_id,
        :client_name,
        :fecha_devolucion,
        :comments_devolucion,
        :caja_id,
        :cajero_id,
        :sale_id,
        sale_devolucion_detalle: [:product_id, :cantidad, :precio_unitario]
      )
    end
  end
end
