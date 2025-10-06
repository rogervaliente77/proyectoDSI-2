module Admin
  class DevolucionesController < ApplicationController
    before_action :set_devolucion, only: %i[edit update destroy]
    layout 'dashboard'

    def index
      @devoluciones = Devolucion.all.order_by(created_at: :desc)
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

    def autorizar_devolucion
      @devolucion = Devolucion.find(params[:id])
    

      # Si se está autorizando (no desautorizando)
      if !@devolucion.is_authorized
        # Guardamos la fecha de autorización
        @devolucion.authorized_at = Time.current
    
        # Por cada producto en el detalle, creamos un registro en ReturnedProduct
        @devolucion.sale_devolucion_detalle.each do |detalle|
          # Saltar productos con cantidad 0 o vacía
          next if detalle["cantidad"].to_f <= 0
        
          begin
            product = Product.find(BSON::ObjectId.from_string(detalle["product_id"]))
          rescue Mongoid::Errors::DocumentNotFound
            next
          end
        
          # Aquí ya puedes crear el ReturnedProduct
          ReturnedProduct.create!(
            product: product,
            sale: @devolucion.sale,
            devolucion: @devolucion,
            quantity: detalle["cantidad"].to_i,
            unit_price: detalle["precio_unitario"].to_f,
            discount: 0,  # si quieres traerlo de otro lado, puedes agregarlo
            returned_at: Time.current
          )
        end        
      else
        # Si se desautoriza, limpiamos la fecha
        @devolucion.authorized_at = nil
      end
    
      # Finalmente, actualizamos el estado de autorización
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
