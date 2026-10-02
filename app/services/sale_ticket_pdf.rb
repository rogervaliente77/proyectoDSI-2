require 'prawn'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'stringio'

class SaleTicketPdf < Prawn::Document
  # 80mm = 226.77pt. Calculamos la altura aproximada según la cantidad de ítems
  def initialize(sale)
    @sale = sale
    @product_sales = sale.product_sales
    @config = SiteConfiguration.first

    # Ancho 80mm (226.77 pt), margen lateral reducido (8pt)
    page_width = 226.77
    page_height = calcular_altura_ticket

    super(page_size: [page_width, page_height], margin: [10, 8, 10, 8])

    generate_pdf
  end

  def generate_pdf
    encabezado
    datos_venta
    separador
    tabla_productos
    separador
    totales
    separador
    codigo_de_barras
    pie_de_pagina
  end

  private

  def calcular_altura_ticket
    # Base fija (encabezado, cliente, totales, barcode, footer): ~300pt
    # ~25pt por cada producto
    300 + (@product_sales.count * 25)
  end

  def encabezado
    nombre_empresa = @config&.company_name.presence || "BIMERS MOTORS CARS"
    direccion = @config&.address.presence || @config&.short_address.presence || "C. El Algodon Casa 114, San Salvador"
    telefono = @config&.phone.presence || @config&.tel.presence || "2262 1909"

    # Logo centrado
    logo_path = Rails.root.join('app/assets/images/logo_bimers.png')
    if File.exist?(logo_path)
      image logo_path, width: 90, position: :center
      move_down 5
    end

    text nombre_empresa.upcase, size: 9, style: :bold, align: :center
    text direccion, size: 7, align: :center
    text "Tel: #{telefono}", size: 7, align: :center
    move_down 5

    text "TICKET DE VENTA", size: 9, style: :bold, align: :center
    text "N° #{@sale.code}", size: 10, style: :bold, align: :center
    move_down 5
  end

  def datos_venta
    fecha_venta = @sale.created_at ? @sale.created_at.strftime("%d/%m/%Y %H:%M") : Date.today.strftime("%d/%m/%Y %H:%M")
    cliente_nombre = @sale.client_name.presence || "CLIENTE GENERAL"

    font_size 7 do
      text "<b>FECHA:</b> #{fecha_venta}", inline_format: true
      text "<b>CLIENTE:</b> #{cliente_nombre.upcase}", inline_format: true
    end
  end

  def separador
    move_down 3
    stroke_horizontal_rule
    move_down 5
  end

  def tabla_productos
    simbolo = @config&.currency_symbol.presence || "$"

    font_size 7 do
      # Línea de título de tabla
      text_box "CANT/DESC", at: [0, cursor], width: 120, height: 10, style: :bold
      text "SUBTOTAL", style: :bold, align: :right
      move_down 4

      @product_sales.each do |ps|
        cant = ps.quantity || 0
        precio_u = ps.unit_price || 0.0
        pct_desc = ps.discount_porcentage || 0.0
        desc_monetario = ps.discount || 0.0
        subtotal = ps.subtotal || ((precio_u * cant) - desc_monetario)

        # Fila 1: Cantidad x Precio Unitario ---- Subtotal
        text_box "#{cant} x #{simbolo}#{format('%.2f', precio_u)}", at: [0, cursor], width: 120, height: 10
        text "#{simbolo}#{format('%.2f', subtotal)}", align: :right

        # Fila 2: Nombre del producto
        text ps.product&.name.to_s.upcase, style: :bold

        # Descuento si aplica (usamos el monto en dinero ya calculado)
        if desc_monetario > 0
          text "  (Desc. #{format('%.1f', pct_desc)}%: -#{simbolo}#{format('%.2f', desc_monetario)})", color: "555555"
        end

        move_down 3
      end
    end
  end

  def totales
    simbolo = @config&.currency_symbol.presence || "$"
    subtotal_bruto = @product_sales.sum { |ps| (ps.unit_price || 0) * (ps.quantity || 0) }
    total_descuentos = @product_sales.sum { |ps| ps.discount || 0 }
    total_neto = @sale.total_amount || (subtotal_bruto - total_descuentos)

    font_size 8 do
      float { text "SUMAS:" }
      text "#{simbolo}#{format('%.2f', subtotal_bruto)}", align: :right

      if total_descuentos > 0
        float { text "DESCUENTO (-):" }
        text "#{simbolo}#{format('%.2f', total_descuentos)}", align: :right
      end

      move_down 2
      font_size 9 do
        float { text "<b>TOTAL:</b>", inline_format: true }
        text "<b>#{simbolo}#{format('%.2f', total_neto)}</b>", align: :right, inline_format: true
      end
    end
  end

  def codigo_de_barras
    return unless @sale.code.present?

    begin
      barcode = Barby::Code128B.new(@sale.code)
      png_data = Barby::PngOutputter.new(barcode).to_png
      png_io = StringIO.new(png_data)

      image png_io, width: 140, height: 28, position: :center
      move_down 2
      text @sale.code, size: 7, align: :center, character_spacing: 1
      move_down 5
    rescue StandardError => e
      Rails.logger.error("Error al generar código de barras en ticket: #{e.message}")
    end
  end

  def pie_de_pagina
    text "¡Gracias por su compra!", size: 8, style: :bold, align: :center
  end
end