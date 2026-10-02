require 'prawn'
require 'prawn/table'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'stringio'

class SalePdf < Prawn::Document
  def initialize(sale)
    # Margen superior ajustado a 100pt para dar espacio al nuevo header sin desbordar
    super(page_size: 'LETTER', margin: [100, 30, 30, 30])
    @sale = sale
    @product_sales = sale.product_sales
    @config = SiteConfiguration.first

    generate_pdf
  end

  def generate_pdf
    repeat(:all) do
      encabezado
    end

    datos_generales
    tabla_productos
    totales
    codigo_de_barras
    pie_de_pagina
  end

  private

  def encabezado
    # Posicionamos la caja en bounds.top (límite superior dentro de la página)
    bounding_box([0, bounds.top + 70], width: 552, height: 65) do
      # 1. Logo alineado arriba a la izquierda
      logo_path = Rails.root.join('app/assets/images/logo_bimers.png')
      if File.exist?(logo_path)
        image logo_path, at: [0, 73], width: 115
      end

      # 2. Datos de la empresa (Centro)
      bounding_box([125, cursor], width: 270) do
        nombre_empresa = @config&.company_name.presence || "BIMERS MOTORS CARS"
        direccion = @config&.address.presence || @config&.short_address.presence || "C. El Algodon Casa 114, San Salvador"
        telefono = @config&.phone.presence || @config&.tel.presence || "2262 1909"
        email = @config&.company_email.presence || "bimersmotor.cars@gmail.com"

        text nombre_empresa.upcase, size: 12, style: :bold, align: :center
        move_down 3
        text direccion, size: 7, align: :center, color: "444444"
        text "Tel: #{telefono} | Email: #{email}", size: 7, align: :center, color: "444444"
      end

      # 3. Recuadro del Comprobante (Derecha - alineado dentro de la página)
      bounding_box([405, cursor + 40], width: 147, height: 40) do
        stroke_bounds
        move_down 6
        text "COMPROBANTE", size: 8, style: :bold, align: :center
        text "DE VENTA", size: 8, style: :bold, align: :center
        move_down 3
        text "N° #{@sale.code}", size: 10, style: :bold, align: :center, color: "CC0000"
      end
    end
  end

  def datos_generales
    fecha_venta = @sale.created_at ? @sale.created_at.strftime("%d/%m/%Y %H:%M") : Date.today.strftime("%d/%m/%Y %H:%M")
    cliente_nombre = @sale.client_name.presence || "CLIENTE GENERAL / CONTADO"

    datos = [
      ["<b>CLIENTE:</b>", cliente_nombre.upcase, "<b>FECHA:</b>", fecha_venta],
      ["<b>CÓDIGO VENTA:</b>", @sale.code.to_s, "", ""]
    ]

    font_size 8

    datos.each do |row|
      float do
        bounding_box([0, cursor], width: 552) do
          text_box row[0], at: [0, cursor], width: 85, inline_format: true
          text_box row[1], at: [85, cursor], width: 250, inline_format: true

          if row[2].present?
            text_box row[2], at: [350, cursor], width: 50, inline_format: true
            text_box row[3], at: [400, cursor], width: 150, inline_format: true
          end
        end
      end
      move_down 14
    end

    move_down 8
  end

  def tabla_productos
    simbolo = @config&.currency_symbol.presence || "$"
    
    filas = [["Cant.", "Descripción / Producto", "P. Unit.", "Desc. %", "Val. Desc.", "Subtotal"]]

    # Solo agregamos los ítems reales comprados
    @product_sales.each do |ps|
      cant = ps.quantity || 0
      precio_u = ps.unit_price || 0.0
      pct_desc = ps.discount_porcentage || 0.0
      desc_monetario = ps.discount || 0.0
      subtotal = ps.subtotal || ((precio_u * cant) - desc_monetario)

      filas << [
        cant.to_s,
        ps.product&.name.to_s.upcase,
        "#{simbolo}#{format('%.2f', precio_u)}",
        "#{format('%.1f', pct_desc)}%",
        "#{simbolo}#{format('%.2f', desc_monetario)}",
        "#{simbolo}#{format('%.2f', subtotal)}"
      ]
    end

    table(filas, header: true, column_widths: [35, 217, 75, 55, 85, 85]) do |t|
      t.row(0).background_color = 'F0F0F0'
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).size = 8

      t.columns(0).align = :center
      t.columns(1).align = :left
      t.columns(2..5).align = :right

      t.cells.size = 8
      t.cells.padding = 5
      t.cells.border_width = 0.5
      t.cells.border_color = "CCCCCC"
    end

    move_down 12
  end

  def totales
    simbolo = @config&.currency_symbol.presence || "$"
    
    subtotal_bruto = @product_sales.sum { |ps| (ps.unit_price || 0) * (ps.quantity || 0) }
    total_descuentos = @product_sales.sum { |ps| ps.discount || 0 }
    total_neto = @sale.total_amount || (subtotal_bruto - total_descuentos)

    tabla_totales = [
      ["SUMAS:", "#{simbolo}#{format('%.2f', subtotal_bruto)}"],
      ["DESCUENTO (-):", "#{simbolo}#{format('%.2f', total_descuentos)}"],
      ["TOTAL A PAGAR:", "#{simbolo}#{format('%.2f', total_neto)}"]
    ]

    bounding_box([0, cursor], width: 552) do
      table(tabla_totales, position: :right, column_widths: [100, 85]) do |t|
        t.row(0..1).size = 8
        t.row(2).font_style = :bold
        t.row(2).size = 9
        t.row(2).background_color = 'EAEAEA'
        
        t.columns(0).align = :left
        t.columns(1).align = :right
        t.cells.border_width = 0.5
        t.cells.border_color = "CCCCCC"
      end
    end

    move_down 20
  end

  def codigo_de_barras
    return unless @sale.code.present?

    begin
      barcode = Barby::Code128B.new(@sale.code)
      png_data = Barby::PngOutputter.new(barcode).to_png
      png_io = StringIO.new(png_data)

      bounding_box([0, cursor], width: 552) do
        image png_io, width: 170, height: 32, position: :center
        move_down 2
        text @sale.code, size: 7, align: :center, character_spacing: 1
      end
    rescue StandardError => e
      Rails.logger.error("Error al generar código de barras: #{e.message}")
    end
  end

  def pie_de_pagina
    bounding_box([0, 15], width: 552, height: 15) do
      stroke_horizontal_rule
      move_down 3
      text "¡Gracias por su compra!", size: 8, style: :bold, align: :center
    end
  end
end