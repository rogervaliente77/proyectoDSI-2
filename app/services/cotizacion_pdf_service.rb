# app/services/cotizacion_pdf_service.rb
require 'prawn'
require 'prawn/table'

class CotizacionPdfService
  def initialize(cotizacion)
    @cotizacion = cotizacion

    # Colores corporativos
    @c_navy = '1A365D'
    @c_blue = '2B6CB0'
    @c_dark_grey = '2D3748'
    @c_green = '276749'
    @c_gold = 'B7791F'
    @c_light_bg = 'F7FAFC'
  end

  def call
    # Configuración de página vertical (portrait), tamaño carta y márgenes
    pdf = Prawn::Document.new(
      page_size: 'LETTER',
      page_layout: :portrait,
      margin: [30, 30, 30, 30]
    )

    generar_documento(pdf)
    pdf.render
  end

  private

  def generar_documento(pdf)
    # 1. Encabezado fijo superior
    dibujar_encabezado(pdf)

    # 2. Datos del Cliente
    dibujar_datos_cliente(pdf)
    pdf.move_down 6

    # 3. I. Condiciones Generales
    dibujar_condiciones(pdf)
    pdf.move_down 10

    # 4. Detalle por Vehículo
    vehiculos = @cotizacion.vehiculos || []
    
    gran_total_servicios = 0.0
    gran_total_repuestos = 0.0
    gran_total_adicionales = 0.0

    vehiculos.each_with_index do |v, idx|
      # Si no es el primer vehículo, hacemos salto de página y repetimos encabezado
      if idx > 0
        pdf.start_new_page
        dibujar_encabezado(pdf)
      end

      sub_serv = dibujar_tabla_servicios(pdf, v, idx)
      pdf.move_down 8

      sub_rep = dibujar_tabla_repuestos(pdf, v)
      pdf.move_down 8

      sub_adic = dibujar_tabla_adicionales(pdf, v)
      pdf.move_down 6

      total_vehiculo = sub_serv + sub_rep + sub_adic
      dibujar_resumen_vehiculo(pdf, v, idx, total_vehiculo)
      pdf.move_down 12

      gran_total_servicios += sub_serv
      gran_total_repuestos += sub_rep
      gran_total_adicionales += sub_adic
    end

    # 5. Resumen General de la Oferta
    if vehiculos.any?
      pdf.start_new_page
      dibujar_encabezado(pdf)
      dibujar_resumen_general(pdf, gran_total_servicios, gran_total_repuestos, gran_total_adicionales)
    end
  end

  def dibujar_encabezado(pdf)
    logo_path = Rails.root.join('public', 'logo_bimers.png')
    
    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
      if File.exist?(logo_path)
        pdf.image logo_path, at: [0, 55], width: 120
      end

      # Ancho ajustado a 300pt para formato vertical
      pdf.bounding_box([pdf.bounds.width - 300, 50], width: 300, height: 50) do
        pdf.text "BIMERS S.A DE C.V", align: :right, style: :bold, size: 11, color: @c_navy
        pdf.text "TALLER AUTOMOTRIZ ESPECIALIZADO", align: :right, style: :bold, size: 7.5, color: @c_blue
        pdf.text "(Mecánica, electrónica, enderezado, pintura, repuestos y A/C)", align: :right, size: 6, color: '4A5568', style: :italic
        
        pdf.move_down 2
        num = @cotizacion.try(:numero_cotizacion).presence || @cotizacion.id.to_s
        fecha = Time.current.strftime("%d/%m/%Y")
        pdf.text "N° COTIZACIÓN: #{num}   |   Fecha: #{fecha}", align: :right, style: :bold, size: 7.5, color: @c_navy
      end
    end


    pdf.stroke_color @c_navy
    pdf.move_down 10
    pdf.stroke_horizontal_rule
    pdf.move_down 10
  end

  def dibujar_datos_cliente(pdf)
    data = [
      ["<b>Cliente:</b> #{@cotizacion.try(:cliente_nombre) || 'N/A'}", "<b>Licitación Año:</b> #{@cotizacion.try(:anio_licitacion) || 'N/A'}"]
    ]
    pdf.table(data, width: pdf.bounds.width, cell_style: { inline_format: true, size: 8, padding: 3, background_color: @c_light_bg, border_color: 'E2E8F0' }) do |t|
      t.column(0).width = pdf.bounds.width * 0.65
      t.column(1).width = pdf.bounds.width * 0.35
      t.column(1).align = :right
    end
  end

  def dibujar_condiciones(pdf)
    pdf.table([["I. CONDICIONES GENERALES"]], width: pdf.bounds.width, cell_style: { background_color: @c_navy, text_color: 'FFFFFF', font_style: :bold, size: 8, padding: 3 })
    
    data = [
      ["<b>Plazo de Entrega:</b> #{@cotizacion.try(:plazo_entrega) || 'N/A'}", "<b>Lugar de Entrega:</b> #{@cotizacion.try(:lugar_entrega) || 'N/A'}"],
      ["<b>Pago Maint. Preventivo:</b> #{@cotizacion.try(:condiciones_pago_preventivo) || 'N/A'}", "<b>Pago Maint. Correctivo:</b> #{@cotizacion.try(:condiciones_pago_correctivo) || 'N/A'}"]
    ]

    pdf.table(data, width: pdf.bounds.width, cell_style: { inline_format: true, size: 7, padding: 3, border_color: 'CBD5E0' }) do |t|
      t.column(0).width = pdf.bounds.width * 0.5
      t.column(1).width = pdf.bounds.width * 0.5
    end
  end

  def dibujar_tabla_servicios(pdf, v, idx)
    correlativo = v.try(:numero_correlativo).presence || (idx + 1)
    header_text = "UNIDAD N° #{correlativo} — #{v.try(:tipo)} #{v.try(:marca)} #{v.try(:modelo)} (#{v.try(:anio)}) | PLACA: #{v.try(:placa)} | VIN: #{v.try(:vin)}"
    
    pdf.table([[header_text]], width: pdf.bounds.width, cell_style: { background_color: @c_blue, text_color: 'FFFFFF', font_style: :bold, size: 7.5, padding: 3 })
    pdf.move_down 4

    pdf.text "1. DETALLE DE SERVICIOS Y MANO DE OBRA", style: :bold, size: 7.5, color: @c_navy
    pdf.move_down 2

    servicios = v.try(:cotizacion_servicios) || []
    subtotal = 0.0

    data = [["Mantenimiento", "Sistema", "Descripción del Servicio", "Precio ($)"]]
    
    servicios.each do |s|
      p = s.try(:precio).to_f
      subtotal += p
      data << [
        s.try(:tipo_mantenimiento) || '-',
        s.try(:sistema) || '-',
        s.try(:servicio_descripcion) || '-',
        "$#{sprintf('%.2f', p)}"
      ]
    end

    data << [
      { content: "SUBTOTAL SERVICIOS:", colspan: 3, align: :right, font_style: :bold }, 
      { content: "$#{sprintf('%.2f', subtotal)}", align: :right, font_style: :bold, text_color: @c_blue }
    ]

    # Columnas ajustadas para el ancho portrait (552pt total)
    pdf.table(data, width: pdf.bounds.width, header: true, cell_style: { size: 6.5, padding: 2.5, border_color: 'CBD5E0' }) do |t|
      t.row(0).background_color = '2D3748'
      t.row(0).text_color = 'FFFFFF'
      t.row(0).font_style = :bold
      
      t.column(0).width = pdf.bounds.width * 0.18
      t.column(1).width = pdf.bounds.width * 0.22
      t.column(2).width = pdf.bounds.width * 0.45
      t.column(3).width = pdf.bounds.width * 0.15
      t.column(3).align = :right
    end

    subtotal
  end

  def dibujar_tabla_repuestos(pdf, v)
    pdf.text "2. FICHA TÉCNICA DE REPUESTOS Y LUBRICANTES OFERTADOS", style: :bold, size: 7.5, color: @c_green
    pdf.move_down 2

    repuestos = v.try(:repuestos) || []
    subtotal = v.try(:precio_repuestos).to_f

    data = [["Tipo", "Repuesto / Insumo", "Oferta", "Marca", "Origen", "Especificación / Uso"]]

    repuestos.each do |r|
      espec = []
      espec << "<b>Espec:</b> #{r.try(:especificacion)}" if r.try(:especificacion).present?
      espec << "<i>Uso:</i> #{r.try(:comentario_uso)}" if r.try(:comentario_uso).present?

      data << [
        r.try(:tipo_item) || 'Repuesto',
        r.try(:nombre) || '-',
        r.try(:tipo_origen) || '-',
        r.try(:marca) || '-',
        r.try(:pais_origen) || '-',
        espec.join("\n")
      ]
    end

    data << [
      { content: "TOTAL REPUESTOS Y LUBRICANTES:", colspan: 5, align: :right, font_style: :bold }, 
      { content: "$#{sprintf('%.2f', subtotal)}", align: :right, font_style: :bold, text_color: @c_green }
    ]

    # Columnas rediseñadas para ajustar la tabla de repuestos verticalmente
    pdf.table(data, width: pdf.bounds.width, header: true, cell_style: { size: 6, padding: 2.5, border_color: 'CBD5E0', inline_format: true }) do |t|
      t.row(0).background_color = '276749'
      t.row(0).text_color = 'FFFFFF'
      t.row(0).font_style = :bold
      
      t.column(0).width = pdf.bounds.width * 0.13
      t.column(1).width = pdf.bounds.width * 0.25
      t.column(2).width = pdf.bounds.width * 0.10
      t.column(3).width = pdf.bounds.width * 0.12
      t.column(4).width = pdf.bounds.width * 0.10
      t.column(5).width = pdf.bounds.width * 0.30
      t.column(5).align = :left
    end

    subtotal
  end

  def dibujar_tabla_adicionales(pdf, v)
    pdf.text "3. TRABAJOS Y ELEMENTOS ADICIONALES", style: :bold, size: 7.5, color: @c_gold
    pdf.move_down 2

    subtotal = v.try(:precio_consumibles).to_f
    desc = v.try(:consumibles_menores).presence || 'No se registraron consumibles ni trabajos adicionales.'

    data = [
      ["Descripción Insumos / Adicionales"],
      [desc],
      [{ content: "TOTAL ADICIONALES Y CONSUMIBLES: $#{sprintf('%.2f', subtotal)}", align: :right, font_style: :bold, text_color: @c_gold }]
    ]

    pdf.table(data, width: pdf.bounds.width, cell_style: { size: 6.5, padding: 2.5, border_color: 'CBD5E0' }) do |t|
      t.row(0).background_color = 'B7791F'
      t.row(0).text_color = 'FFFFFF'
      t.row(0).font_style = :bold
    end

    subtotal
  end

  def dibujar_resumen_vehiculo(pdf, v, idx, total)
    correlativo = v.try(:numero_correlativo).presence || (idx + 1)
    placa = v.try(:placa).presence || 'S/P'
    data = [
      ["TOTAL UNIDAD N° #{correlativo} (#{placa}):", "$#{sprintf('%.2f', total)}"]
    ]
    pdf.table(data, width: pdf.bounds.width, cell_style: { background_color: @c_navy, text_color: 'FFFFFF', font_style: :bold, size: 8, padding: 3.5 }) do |t|
      t.column(0).width = pdf.bounds.width * 0.7
      t.column(1).width = pdf.bounds.width * 0.3
      t.column(1).align = :right
    end
  end

  def dibujar_resumen_general(pdf, serv, rep, adic)
    total_general = serv + rep + adic

    pdf.table([["RESUMEN GENERAL DE LA OFERTA"]], width: pdf.bounds.width, cell_style: { background_color: @c_navy, text_color: 'FFFFFF', font_style: :bold, size: 8.5, padding: 4 })
    pdf.move_down 2

    data = [
      ["TOTAL SERVICIOS Y MANO DE OBRA:", "$#{sprintf('%.2f', serv)}"],
      ["TOTAL REPUESTOS Y LUBRICANTES:", "$#{sprintf('%.2f', rep)}"],
      ["TOTAL ADICIONALES Y CONSUMIBLES:", "$#{sprintf('%.2f', adic)}"],
      ["TOTAL GENERAL OFERTA:", "$#{sprintf('%.2f', total_general)}"]
    ]

    pdf.table(data, width: pdf.bounds.width, cell_style: { size: 7.5, padding: 4, border_color: 'CBD5E0' }) do |t|
      t.column(0).width = pdf.bounds.width * 0.7
      t.column(0).font_style = :bold
      t.column(1).width = pdf.bounds.width * 0.3
      t.column(1).align = :right
      t.column(1).font_style = :bold
      
      t.row(3).background_color = @c_blue
      t.row(3).text_color = 'FFFFFF'
      t.row(3).size = 9
    end
  end
end