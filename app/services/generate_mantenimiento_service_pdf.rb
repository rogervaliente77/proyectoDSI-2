require 'prawn'
require 'prawn/table'

class GenerateMantenimientoServicePdf < Prawn::Document
  def initialize(service_order)
    # Cambiamos el margen superior de 30 a 110
    super(page_size: 'LETTER', margin: [110, 30, 30, 30])
    @order = service_order
    @client = @order.client_car&.client
    @car = @order.client_car
  
    generate_pdf
  end

  def generate_pdf
    # Dibujar el encabezado en todas las páginas automáticamente
    repeat(:all) do
      encabezado
    end

    # El contenido fluye normalmente a través de las páginas
    datos_generales
    tabla_servicios_y_repuestos
    totales
    firmas
    pie_de_pagina
  end

  private

  def encabezado
    # Posicionamos la cabecera en la parte superior fija de la página (fuera del margen del flujo)
    bounding_box([0, bounds.top + 80], width: 532, height: 70) do
      logo_path = Rails.root.join('app/assets/images/logo_bimers.png')
      if File.exist?(logo_path)
        image logo_path, at: [0, cursor], width: 130
      end
  
      bounding_box([140, cursor], width: 390) do
        text "BIMERS S.A DE C.V.", size: 14, style: :bold_italic, align: :center
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

    datos = [
      ["<b>CLIENTE:</b>", @client&.nombre.to_s.upcase, "<b>F. ENTRADA:</b>", fecha_ent, "<b>COT. N°</b>", @order.numero_orden.to_s],
      ["<b>MARCA:</b>", @car&.marca.to_s.upcase, "<b>COLOR:</b>", @car&.color.to_s.upcase, "<b>KM. ENT.</b>", "#{@order.km_entrada} M"],
      ["<b>MODELO:</b>", @car&.modelo.to_s.upcase, "<b>PLACA:</b>", @car&.placa.to_s.upcase, "<b>KM. SAL.</b>", "#{@order.km_salida} M"],
      ["<b>AÑO:</b>", @car&.anio.to_s, "<b>VIN:</b>", @car&.vin.to_s.upcase, "<b>F. SALIDA:</b>", fecha_sal],
      ["<b>TELÉFONO:</b>", @client&.telefono.to_s, "<b>E-MAIL:</b>", @client&.email.to_s, "<b>PAGO:</b>", @order.forma_pago.presence || 'EFECTIVO'],
      ["<b>TÉCNICO:</b>", @order.tecnico.presence || 'TALLER BIMERS', "<b>FORMA PAGO:</b>", @order&.forma_pago.to_s, "", ""]
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
    filas = [["Cantidad", "DESCRIPCION", "PRECIO UNIT.", "PRECIO TOTAL"]]

    # 1. Mano de obra / Servicios
    if @order.respond_to?(:order_services)
      @order.order_services.each do |s|
        filas << [
          s.cantidad.to_s,
          s.descripcion.to_s.upcase,
          "$ #{format('%.2f', s.precio_unitario || 0)}",
          "$ #{format('%.2f', s.precio_total || 0)}"
        ]
      end
    end

    # 2. Repuestos / Insumos
    if @order.respond_to?(:order_items)
      @order.order_items.each do |i|
        filas << [
          i.cantidad.to_s,
          "#{i.tipo.to_s.upcase}: #{i.descripcion.to_s.upcase}",
          "$ #{format('%.2f', i.precio_unitario || 0)}",
          "$ #{format('%.2f', i.precio_total || 0)}"
        ]
      end
    end

    # FILAS DINÁMICAS: Si hay menos de 5 ítems, rellenamos opcionalmente hasta 5 para estética.
    # Si hay más, la tabla crece según la cantidad de datos recibidos.
    min_filas = 5
    items_actuales = filas.size - 1
    if items_actuales < min_filas
      (min_filas - items_actuales).times do
        filas << ["", "", "$ -", "$ -"]
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
    bounding_box([0, cursor], width: 532) do
      tabla_totales = [
        ["SUBTOTAL:", "$ #{format('%.2f', @order.subtotal || 0)}"],
        ["TOTAL GENERAL:", "$ #{format('%.2f', @order.total || 0)}"]
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
    # Bounding Box con posición absoluta en la parte inferior (at: [0, 90])
    # Se mantendrá estático justo encima del footer.
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
    bounding_box([0, 25], width: 532, height: 25) do
      stroke_horizontal_rule
      move_down 5
      text "Calle Algodon, pasaje San Jorge, local #114, San Antonio Abad, San Salvador", size: 7, align: :center, color: "555555"
      text "Teléfonos: 2262-1909, 7834-9237 | E-mail: bimersmotor.cars@gmail.com", size: 7, align: :center, color: "555555"
    end
  end
end