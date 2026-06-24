module Admin
  class MovimientosPlanillaController < Admin::ApplicationController
    layout 'dashboard'
    before_action :set_empleado

    def index
      # Rango de fechas por defecto: Desde el 1 del mes actual hasta el día de hoy
      @fecha_inicio = params[:fecha_inicio].present? ? Date.parse(params[:fecha_inicio]) : Date.today.beginning_of_month
      @fecha_fin = params[:fecha_fin].present? ? Date.parse(params[:fecha_fin]) : Date.today

      # Filtro de movimientos en el rango de fechas seleccionado
      @movimientos = @empleado.movimientos_planilla.where(
        :fecha.gte => @fecha_inicio, 
        :fecha.lte => @fecha_fin
      ).order_by(fecha: :desc)
    end

    def new
      @movimiento = @empleado.movimientos_planilla.new(fecha: Date.today)
    end

    def create
      @empleado = Empleado.find(params[:empleado_id])
      @movimiento = @empleado.movimientos_planilla.new(movimiento_params)
      
      if @movimiento.save
        # CAMBIADO AQUÍ: Se agregó _index antes de _path
        redirect_to admin_empleado_movimientos_planilla_index_path(@empleado), notice: "Registro guardado correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @movimiento = @empleado.movimientos_planilla.find(params[:id])
      if @movimiento.procesado
        redirect_to admin_empleado_movimientos_planilla_path(@empleado), alert: "No se puede eliminar un movimiento que ya fue procesado en una planilla."
      else
        @movimiento.destroy
        redirect_to admin_empleado_movimientos_planilla_path(@empleado), notice: "Registro eliminado con éxito."
      end
    end

    private

    def set_empleado
      @empleado = Empleado.find(params[:empleado_id])
    end

    def movimiento_params
      params.require(:movimiento_planilla).permit(:tipo, :monto, :fecha, :descripcion)
    end
  end
end