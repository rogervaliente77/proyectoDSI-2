module Admin
  class CotizacionesController < Admin::ApplicationController
    before_action :set_cotizacion, only: [:edit, :update, :destroy, :datos_pdf]
    layout 'dashboard'

    def index
      @cotizaciones = Cotizacion.all
    end

    def new
      @cotizacion = Cotizacion.new
      vehiculo = @cotizacion.vehiculos.build
      
      # Nos aseguramos de que existan plantillas precargadas en la BD
      PlantillaCategoria.cargar_iniciales! if PlantillaCategoria.count.zero?

      # Precargamos los servicios basados en PlantillaCategoria
      PlantillaCategoria.all.each do |plantilla|
        vehiculo.cotizacion_servicios.build(
          tipo_mantenimiento: plantilla.tipo_mantenimiento,
          sistema: plantilla.categoria,
          servicio_descripcion: plantilla.descripcion_tareas
        )
      end
    end

    def create
      @cotizacion = Cotizacion.new(cotizacion_params)
      if @cotizacion.save
        redirect_to admin_cotizaciones_path, notice: "Cotización guardada exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      PlantillaCategoria.cargar_iniciales! if PlantillaCategoria.count.zero?

      @cotizacion.vehiculos.each do |vehiculo|
        PlantillaCategoria.all.each do |plantilla|
          unless vehiculo.cotizacion_servicios.where(sistema: plantilla.categoria).exists?
            vehiculo.cotizacion_servicios.build(
              tipo_mantenimiento: plantilla.tipo_mantenimiento,
              sistema: plantilla.categoria,
              servicio_descripcion: plantilla.descripcion_tareas
            )
          end
        end
      end
    end

    def update
      if @cotizacion.update(cotizacion_params)
        redirect_to admin_cotizaciones_path, notice: "Cotización actualizada exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @cotizacion.destroy
      redirect_to admin_cotizaciones_path, notice: "Cotización eliminada exitosamente."
    end

    def datos_pdf
      render json: {
        _id: @cotizacion.id.to_s,
        numero_cotizacion: @cotizacion.try(:numero_cotizacion),
        cliente_nombre: @cotizacion.try(:cliente_nombre),
        anio_licitacion: @cotizacion.try(:anio_licitacion),
        plazo_entrega: @cotizacion.try(:plazo_entrega),
        lugar_entrega: @cotizacion.try(:lugar_entrega),
        condiciones_pago_preventivo: @cotizacion.try(:condiciones_pago_preventivo),
        condiciones_pago_correctivo: @cotizacion.try(:condiciones_pago_correctivo),
        vehiculos: (@cotizacion.vehiculos || []).map { |v|
          {
            numero_correlativo: v.try(:numero_correlativo),
            tipo: v.try(:tipo),
            marca: v.try(:marca),
            modelo: v.try(:modelo),
            anio: v.try(:anio),
            placa: v.try(:placa),
            vin: v.try(:vin),
            
            # Campos de Totales de la Opción A:
            precio_repuestos: v.try(:precio_repuestos).to_f,
            consumibles_menores: v.try(:consumibles_menores),
            precio_consumibles: v.try(:precio_consumibles).to_f,
    
            cotizacion_servicios: (v.try(:cotizacion_servicios) || []).map { |s|
              {
                tipo_mantenimiento: s.try(:tipo_mantenimiento),
                sistema: s.try(:sistema),
                servicio_descripcion: s.try(:servicio_descripcion),
                precio: s.try(:precio).to_f
              }
            },
            repuestos: (v.try(:repuestos) || []).map { |r|
              {
                tipo_item: r.try(:tipo_item),
                nombre: r.try(:nombre),
                tipo_origen: r.try(:tipo_origen),
                marca: r.try(:marca),
                pais_origen: r.try(:pais_origen),
                especificacion: r.try(:especificacion),
                comentario_uso: r.try(:comentario_uso)
              }
            }
          }
        }
      }
    end

    # app/controllers/admin/cotizaciones_controller.rb
    def descargar_pdf
      @cotizacion = Cotizacion.find(params[:id])
      
      pdf_data = CotizacionPdfService.new(@cotizacion).call
      
      send_data pdf_data,
                filename: "Cotizacion_#{@cotizacion.numero_cotizacion.presence || @cotizacion.id}.pdf",
                type: "application/pdf",
                disposition: "inline"
    end

    private

    def set_cotizacion
      @cotizacion = Cotizacion.find(params[:id])
    end

    # def cotizacion_params
    #   params.require(:cotizacion).permit(
    #     :numero_cotizacion, :cliente_nombre, :anio_licitacion,
    #     :plazo_entrega, :lugar_entrega,
    #     :condiciones_pago_preventivo, :condiciones_pago_correctivo,
    #     vehiculos_attributes: [
    #       :id, :_destroy, :numero_correlativo, :tipo, :marca, :modelo, :anio, :placa, :consumibles_menores,
    #       :precio_repuestos, # <-- AQUÍ: El precio global para toda la sección de repuestos/lubricantes
    #       cotizacion_servicios_attributes: [
    #         :id, :_destroy, :tipo_mantenimiento, :sistema, :servicio_descripcion, :precio
    #       ],
    #       repuestos_attributes: [
    #         :id, :_destroy, :tipo_item, :nombre, :tipo_origen, :marca, :pais_origen, :especificacion, :comentario_uso
    #         # (Se remueve :precio de aquí porque ya no es por repuesto individual)
    #       ],
    #       adicionales_attributes: [:id, :descripcion, :precio, :_destroy]
    #     ]
    #   )
    # end
    # En tu CotizacionesController
    def cotizacion_params
      params.require(:cotizacion).permit(
        :numero_cotizacion, :cliente_nombre, :anio_licitacion, :plazo_entrega, 
        :lugar_entrega, :condiciones_pago_preventivo, :condiciones_pago_correctivo,
        vehiculos_attributes: [
          :id, :_destroy, :numero_correlativo, :tipo, :marca, :modelo, :anio, :placa, :vin,
          :precio_repuestos, :consumibles_menores, :precio_consumibles, # <-- CLAVE AQUÍ
          cotizacion_servicios_attributes: [:id, :_destroy, :sistema, :servicio_descripcion, :tipo_mantenimiento, :precio],
          repuestos_attributes: [:id, :_destroy, :tipo_item, :nombre, :tipo_origen, :marca, :pais_origen, :especificacion, :comentario_uso]
        ]
      )
    end

  end
end
