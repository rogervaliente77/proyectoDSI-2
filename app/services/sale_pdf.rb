# app/services/sale_pdf.rb
require 'prawn'
require 'prawn/table'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'stringio'

class SalePdf
  def initialize(sale)
    @sale = sale
    @product_sales = sale.product_sales
  end

  def generate
    Prawn::Document.new do |pdf|
      # Título
      pdf.text "Comprobante de Venta", size: 22, style: :bold, align: :center
      pdf.move_down 10

      # Información general
      pdf.text "Código: #{@sale.code}", size: 12
      pdf.text "Cliente: #{@sale.client_name}", size: 12
      pdf.text "Fecha: #{@sale.created_at.strftime('%d/%m/%Y %H:%M')}", size: 12
      pdf.move_down 10

      # Código de barras basado en sale.code
      if @sale.code.present?
        barcode = Barby::Code128B.new(@sale.code)
        png = StringIO.new(Barby::PngOutputter.new(barcode).to_png)
        pdf.image png, width: 200, height: 50, position: :center
        pdf.move_down 20
      end

      # Tabla de productos
      pdf.table table_data, header: true, width: pdf.bounds.width do
        row(0).font_style = :bold
        columns(1..4).align = :right
      end

      pdf.move_down 15
      pdf.text "Total: $#{'%.2f' % @sale.total_amount}", size: 14, style: :bold, align: :right
    end.render
  end

  private

  def table_data
    [["Producto", "Cantidad", "Precio Unitario", "Descuento", "Subtotal"]] +
      @product_sales.map do |ps|
        subtotal = (ps.quantity * ps.unit_price) - ps.discount
        [
          ps.product.name,
          ps.quantity,
          "$#{'%.2f' % ps.unit_price}",
          "$#{'%.2f' % ps.discount}",
          "$#{'%.2f' % subtotal}"
        ]
      end
  end
end
