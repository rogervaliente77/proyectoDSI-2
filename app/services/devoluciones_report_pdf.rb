# app/services/devoluciones_report_pdf.rb
require 'prawn'
require 'prawn/table'

class DevolucionesReportPdf
  def initialize(devoluciones, start_date = nil, end_date = nil)
    @devoluciones = devoluciones
    @start_date = start_date
    @end_date = end_date
  end

  def generate
    Prawn::Document.new do |pdf|
      # Título
      pdf.text "Reporte de Devoluciones", size: 22, style: :bold, align: :center
      pdf.move_down 10

      # Fecha del rango si existe
      if @start_date && @end_date
        pdf.text "Desde: #{@start_date.strftime('%d/%m/%Y')} - Hasta: #{@end_date.strftime('%d/%m/%Y')}", size: 12
        pdf.move_down 10
      end

      # Tabla de devoluciones
      pdf.table table_data, header: true, width: pdf.bounds.width do
        row(0).font_style = :bold
        columns(0..6).align = :center
      end
    end.render
  end

  private

  def table_data
    [["Cliente", "Fecha", "Comentarios", "Caja", "Cajero", "Venta", "Autorizada?"]] +
      @devoluciones.map do |d|
        [
          d.client_name.presence || "—",
          d.fecha_devolucion&.strftime("%d/%m/%Y %H:%M") || "—",
          d.comments_devolucion.presence || "Sin comentarios",
          d.caja&.nombre || "—",
          d.cajero&.nombre || "—",
          d.sale&.code || "—",
          d.is_authorized ? "Sí" : "No"
        ]
      end
  end
end
