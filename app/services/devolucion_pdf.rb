# # ./app/services/devolucion_pdf.rb
# require 'prawn'
# require 'prawn/table'
# require 'barby'
# require 'barby/barcode/code_128'
# require 'barby/outputter/png_outputter'
# require 'stringio'

# class DevolucionPdf
#   def initialize(devolucion)
#     @devolucion = devolucion
#     @detalle = devolucion.sale_devolucion_detalle
#   end

#   def generate
#     Prawn::Document.new do |pdf|
#       # Título
#       pdf.text "Comprobante de Devolución", size: 22, style: :bold, align: :center
#       pdf.move_down 10

#       # Información general
#       pdf.text "ID Devolución: #{@devolucion.id}", size: 12
#       pdf.text "Cliente: #{@devolucion.client_name}", size: 12
#       pdf.text "Fecha: #{@devolucion.fecha_devolucion&.strftime('%d/%m/%Y %H:%M') || '—'}", size: 12
#       pdf.text "Venta Asociada: #{@devolucion.sale&.code || '—'}", size: 12
#       pdf.text "Cajero: #{@devolucion.cajero&.nombre || '—'}", size: 12
#       pdf.text "Caja: #{@devolucion.caja&.nombre || '—'}", size: 12
#       pdf.move_down 10

#       # Código de barras basado en ID de la devolución
#       barcode = Barby::Code128B.new(@devolucion.id.to_s)
#       png = StringIO.new(Barby::PngOutputter.new(barcode).to_png)
#       pdf.image png, width: 200, height: 50, position: :center
#       pdf.move_down 20

#       # Tabla de productos devueltos
#       pdf.table table_data, header: true, width: pdf.bounds.width do
#         row(0).font_style = :bold
#         columns(1..5).align = :right
#       end

#       pdf.move_down 15
#       pdf.text "Total a devolver: $#{'%.2f' % @devolucion.total_a_devolver}", size: 14, style: :bold, align: :right
#     end.render
#   end

#   private

#   def table_data
#     [["Producto", "Cantidad", "Precio Unitario", "Subtotal"]] +
#       @detalle.map do |item|
#         product = Product.where(id: item['product_id']).first
#         subtotal = item['cantidad'].to_i * item['precio_unitario'].to_f
#         [
#           product&.name || "—",
#           item['cantidad'],
#           "$#{'%.2f' % item['precio_unitario']}",
#           "$#{'%.2f' % subtotal}"
#         ]
#       end
#   end
# end

# ./app/services/devolucion_pdf.rb
require 'prawn'
require 'prawn/table'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'stringio'

class DevolucionPdf
  def initialize(devolucion)
    @devolucion = devolucion
    @detalle = devolucion.sale_devolucion_detalle
  end

  def generate
    Prawn::Document.new do |pdf|
      # Método auxiliar local para limpiar texto
      def sanitize_text(text)
        text.to_s.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
      end

      # Título
      pdf.text sanitize_text("Comprobante de Devolución"), size: 22, style: :bold, align: :center
      pdf.move_down 10

      # Información general
      pdf.text sanitize_text("ID Devolución: #{@devolucion.id}"), size: 12
      pdf.text sanitize_text("Cliente: #{@devolucion.client_name}"), size: 12
      pdf.text sanitize_text("Fecha: #{@devolucion.fecha_devolucion&.strftime('%d/%m/%Y %H:%M') || '—'}"), size: 12
      pdf.text sanitize_text("Venta Asociada: #{@devolucion.sale&.code || '—'}"), size: 12
      pdf.text sanitize_text("Cajero: #{@devolucion.cajero&.nombre || '—'}"), size: 12
      pdf.text sanitize_text("Caja: #{@devolucion.caja&.nombre || '—'}"), size: 12
      pdf.move_down 10

      # Código de barras basado en ID de la devolución
      barcode = Barby::Code128B.new(@devolucion.id.to_s)
      png = StringIO.new(Barby::PngOutputter.new(barcode).to_png)
      pdf.image png, width: 200, height: 50, position: :center
      pdf.move_down 20

      # Tabla de productos devueltos
      sanitized_table = table_data.map { |row| row.map { |cell| sanitize_text(cell) } }

      pdf.table sanitized_table, header: true, width: pdf.bounds.width do
        row(0).font_style = :bold
        columns(1..5).align = :right
      end

      pdf.move_down 15
      pdf.text sanitize_text("Total a devolver: $#{'%.2f' % @devolucion.total_a_devolver}"),
               size: 14, style: :bold, align: :right
    end.render
  end

  private

  def table_data
    [["Producto", "Cantidad", "Precio Unitario", "Subtotal"]] +
      @detalle.map do |item|
        product = Product.where(id: item['product_id']).first
        subtotal = item['cantidad'].to_i * item['precio_unitario'].to_f
        [
          product&.name || "—",
          item['cantidad'],
          "$#{'%.2f' % item['precio_unitario']}",
          "$#{'%.2f' % subtotal}"
        ]
      end
  end
end
