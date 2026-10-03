require 'prawn'
require 'prawn/table'

class GenerateMantenimientoServicePdf < Prawn::Document
  def initialize(service_order)
    super(page_size: 'LETTER', margin: [110, 30, 30, 30])
    @order = service_order
    @client = @order.client_car&.client
    @car = @order.client_car
    @config = SiteConfiguration.first

    generate_pdf
  end

  def generate_pdf
    repeat(:all) do
      encabezado
    end

    datos_generales
    tabla_servicios_y_repuestos
    totales
    firmas
    pie_de_pagina
  end

  private

  def encabezado
    bounding_box([0, bounds.top + 80], width: 532, height: 70) do
      logo_path = Rails.root.join('app/assets/images/logo_bimers.png')
      if File.exist?(logo_path)
        image logo_path, at: [0, cursor + 10], width: 130
      end

      bounding_box([140, cursor], width: 390) do
        nombre_empresa = @config&.company_name.presence || "BIMERS S.A DE C.V."
        text nombre_empresa.upcase, size: 14, style: :bold_italic, align: :center
        text "TALLER AUTOMOTRIZ ESPECIALIZADO", size: 9, style: :bold, align: :center
        text "(Mecánica, electrónica, enderezado, pintura, venta de repuestos, accesorios y A/C)", size: 7, style: :bold, align: :center
        move_down 3
        stroke_horizontal_rule
      end
    end
  end

  def datos_generales
    fecha_ent = @order.fecha_entrada&.strftime("%d/%m/%Y") || Date.today.strftime("%d/%m/%Y")
    fecha_sal = @order.fecha_salida&.strftime("%d/%m/%Y") || "PENDIENTE"

    forma_pago_obj = FormaPago.find_by(codigo: @order.forma_pago)
    nombre_forma_pago = forma_pago_obj&.name || forma_pago_obj&.nombre || 'EFECTIVO'

    datos = [
      ["<b>CLIENTE:</b>", @client&.nombre.to_s.upcase, "<b>F. ENTRADA:</b>", fecha_ent, "<b>ORDEN N°</b>", @order.numero_orden.to_s],
      ["<b>MARCA:</b>", @car&.marca.to_s.upcase, "<b>COLOR:</b>", @car&.color.to_s.upcase, "<b>KM. ENT.</b>", "#{@order.km_entrada} M"],
      ["<b>MODELO:</b>", @car&.modelo.to_s.upcase, "<b>PLACA:</b>", @car&.placa.to_s.upcase, "<b>KM. SAL.</b>", "#{@order.km_salida} M"],
      ["<b>AÑO:</b>", @car&.anio.to_s, "<b>VIN:</b>", @car&.vin.to_s.upcase, "<b>F. SALIDA:</b>", fecha_sal],
      ["<b>TELÉFONO:</b>", @client&.telefono.to_s, "<b>E-MAIL:</b>", @client&.email.to_s, "<b>FORMA PAGO:</b>", nombre_forma_pago.upcase],
      ["<b>TÉCNICO:</b>", @order.tecnico.presence || 'TALLER BIMERS', "", "", "", ""]
    ]

    font_size 8

    datos.each_with_index do |row, index|
      float do
        bounding_box([0, cursor], width: 530) do
          text_box row[0], at: [0, cursor], width: 120, inline_format: true
          text_box row[1], at: [80, cursor], width: 120, inline_format: true

          text_box row[2], at: [200, cursor], width: 75, inline_format: true
          text_box row[3], at: [285, cursor], width: 120, inline_format: true

          text_box row[4], at: [420, cursor], width: 60, inline_format: true
          text_box row[5], at: [480, cursor], width: 80, inline_format: true
        end
      end

      if index == 0
        move_down 24
      else
        move_down 14
      end
    end

    move_down 10
  end

  def tabla_servicios_y_repuestos
    simbolo = @config&.currency_symbol.presence || "$"
    filas = [["Cantidad", "DESCRIPCION", "PRECIO UNIT.", "PRECIO TOTAL"]]

    if @order.respond_to?(:order_services)
      @order.order_services.each do |s|
        filas << [
          s.cantidad.to_s,
          s.descripcion.to_s.upcase,
          "#{simbolo} #{format('%.2f', s.precio_unitario || 0)}",
          "#{simbolo} #{format('%.2f', s.precio_total || 0)}"
        ]
      end
    end

    if @order.respond_to?(:order_items)
      @order.order_items.each do |i|
        filas << [
          i.cantidad.to_s,
          "#{i.tipo.to_s.upcase}: #{i.descripcion.to_s.upcase}",
          "#{simbolo} #{format('%.2f', i.precio_unitario || 0)}",
          "#{simbolo} #{format('%.2f', i.precio_total || 0)}"
        ]
      end
    end

    min_filas = 5
    items_actuales = filas.size - 1
    if items_actuales < min_filas
      (min_filas - items_actuales).times do
        filas << ["", "", "#{simbolo} -", "#{simbolo} -"]
      end
    end

    table(filas, header: true, column_widths: [65, 305, 80, 82]) do |t|
      t.row(0).background_color = 'FFFFFF'
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).size = 9

      t.columns(0).align = :center
      t.columns(0).size = 8

      t.columns(1).align = :left
      t.columns(1).size = 8

      t.columns(2..3).align = :right
      t.columns(2..3).size = 8

      t.cells.border_width = 1.5
    end

    move_down 10
  end

  def totales
    simbolo = @config&.currency_symbol.presence || "$"
    bounding_box([0, cursor], width: 532) do
      tabla_totales = [
        ["SUBTOTAL:", "#{simbolo} #{format('%.2f', @order.subtotal || 0)}"],
        ["TOTAL GENERAL:", "#{simbolo} #{format('%.2f', @order.total || 0)}"]
      ]

      table(tabla_totales, position: :right, column_widths: [100, 82]) do |t|
        t.row(0..1).font_style = :bold
        t.row(0..1).size = 9
        t.columns(0).align = :left
        t.columns(1).align = :right
        t.cells.border_width = 1
      end
    end
  end

  def firmas
    font_size 8
    bounding_box([0, 70], width: 532, height: 40) do
      stroke_horizontal_line 30, 200, at: cursor
      stroke_horizontal_line 330, 500, at: cursor

      move_down 5
      draw_text "Firma del Cliente", at: [80, cursor - 5]
      draw_text "Firma / Taller Recepción", at: [365, cursor - 5]
    end
  end

  def pie_de_pagina
    direccion = @config&.address.presence || @config&.short_address.presence || "Calle Algodon, pasaje San Jorge, local #114, San Antonio Abad, San Salvador"
    telefono = @config&.phone.presence || @config&.tel.presence || "2262-1909"
    email = @config&.company_email.presence || "bimersmotor.cars@gmail.com"

    bounding_box([0, 25], width: 532, height: 25) do
      stroke_horizontal_rule
      move_down 5
      text direccion, size: 7, align: :center, color: "555555"
      text "Teléfono: #{telefono} | E-mail: #{email}", size: 7, align: :center, color: "555555"
    end
  end
end