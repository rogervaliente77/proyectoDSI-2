require 'prawn'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'stringio'

class GenerateMantenimientoServiceTicketPdf < Prawn::Document
  PAGE_WIDTH = 226 # Ancho estándar de 80mm en puntos Prawn

  def initialize(service_order)
    @order = service_order
    @client = @order.client_car&.client
    @car = @order.client_car
    @config = SiteConfiguration.first

    # 1. Calculamos la altura total según el contenido dinámico
    calculated_height = estimate_ticket_height

    # 2. Inicializamos la página con el alto justo (márgenes estrechos de 6pt)
    super(page_size: [PAGE_WIDTH, calculated_height], margin: [8, 6, 8, 6])

    generate_pdf
  end

  def generate_pdf
    encabezado
    datos_cliente_vehiculo
    lista_servicios_y_repuestos
    totales
    codigo_de_barras
    pie_de_pagina
  end

  private

  # Estimar la altura necesaria evita el papel restante en blanco
  def estimate_ticket_height
    # Altura base fija (Encabezado + Cliente/Vehículo + Totales + Barras + Footer + Márgenes)
    base_height = 370 

    total_items = 0
    total_items += @order.order_services.size if @order.respond_to?(:order_services)
    total_items += @order.order_items.size if @order.respond_to?(:order_items)

    # Añadimos ~24pt por cada ítem en la lista (descripción + sublínea de detalle)
    item_height = total_items * 24

    base_height + item_height
  end

  def encabezado
    logo_path = Rails.root.join('app/assets/images/logo_bimers.png')
    if File.exist?(logo_path)
      image logo_path, width: 75, position: :center
      move_down 4
    end

    nombre_empresa = @config&.company_name.presence || "BIMERS S.A DE C.V."
    direccion = @config&.address.presence || @config&.short_address.presence || "C. El Algodon Casa 114, San Salvador"
    telefono = @config&.phone.presence || @config&.tel.presence || "2262-1909"

    text nombre_empresa.upcase, size: 9, style: :bold, align: :center
    text "TALLER AUTOMOTRIZ ESPECIALIZADO", size: 6, style: :bold, align: :center
    text direccion, size: 6, align: :center, color: "444444"
    text "Tel: #{telefono}", size: 6, align: :center, color: "444444"
    move_down 4
    stroke_horizontal_rule
    move_down 4

    text "FACTURA DE SERVICIO N° #{@order.numero_orden}", size: 8, style: :bold, align: :center
    text "Fecha: #{(@order.fecha_entrada || Date.today).strftime('%d/%m/%Y')}", size: 6.5, align: :center
    move_down 4
    stroke_horizontal_rule
    move_down 4
  end

  def datos_cliente_vehiculo
    forma_pago_obj = FormaPago.find_by(codigo: @order.forma_pago)
    nombre_forma_pago = forma_pago_obj&.name || forma_pago_obj&.nombre || 'EFECTIVO'

    font_size 6.5 do
      text "<b>CLIENTE:</b> #{@client&.nombre.to_s.upcase}", inline_format: true
      text "<b>TELÉFONO:</b> #{@client&.telefono.presence || 'N/A'}", inline_format: true
      text "<b>VEHÍCULO:</b> #{@car&.marca.to_s.upcase} #{@car&.modelo.to_s.upcase} (#{@car&.anio})", inline_format: true
      text "<b>PLACA:</b> #{@car&.placa.to_s.upcase} | <b>COLOR:</b> #{@car&.color.to_s.upcase}", inline_format: true
      text "<b>KM. ENT:</b> #{@order.km_entrada} M", inline_format: true
      text "<b>PAGO:</b> #{nombre_forma_pago.upcase} | <b>TÉCNICO:</b> #{@order.tecnico.presence || 'TALLER'}", inline_format: true
    end

    move_down 4
    stroke_horizontal_rule
    move_down 4
  end

  # FORMATO EN BLOQUES DIRECTOS (Maximiza el espacio horizontal)
  def lista_servicios_y_repuestos
    simbolo = @config&.currency_symbol.presence || "$"

    text "<b>DETALLE DE SERVICIOS Y REPUESTOS</b>", size: 7, style: :bold, inline_format: true
    move_down 3

    # 1. Mano de Obra / Servicios
    if @order.respond_to?(:order_services) && @order.order_services.any?
      @order.order_services.each do |s|
        render_item_row(
          cantidad: s.cantidad,
          descripcion: s.descripcion.to_s.upcase,
          precio_unitario: s.precio_unitario,
          precio_total: s.precio_total,
          simbolo: simbolo
        )
      end
    end

    # 2. Repuestos / Insumos
    if @order.respond_to?(:order_items) && @order.order_items.any?
      @order.order_items.each do |i|
        desc = "#{i.tipo.to_s.upcase}: #{i.descripcion.to_s.upcase}"
        render_item_row(
          cantidad: i.cantidad,
          descripcion: desc,
          precio_unitario: i.precio_unitario,
          precio_total: i.precio_total,
          simbolo: simbolo
        )
      end
    end

    move_down 2
    stroke_horizontal_rule
    move_down 4
  end

  def render_item_row(cantidad:, descripcion:, precio_unitario:, precio_total:, simbolo:)
    # Línea 1: Descripción completa con salto de línea automático si es larga
    font_size 6.5 do
      text descripcion, style: :bold
    end

    # Línea 2: Desglose formateado (Cantidad x Unitario = Total) alineado
    cant_unit_str = "  #{cantidad} x #{simbolo}#{format('%.2f', precio_unitario || 0)}"
    total_str = "#{simbolo}#{format('%.2f', precio_total || 0)}"

    font_size 6.5 do
      float { text cant_unit_str, color: "555555" }
      text total_str, align: :right, style: :bold
    end

    move_down 3
  end

  def totales
    simbolo = @config&.currency_symbol.presence || "$"

    font_size 7 do
      float { text "SUBTOTAL:", style: :bold }
      text "#{simbolo}#{format('%.2f', @order.subtotal || 0)}", align: :right
      move_down 2

      float { text "TOTAL GENERAL:", style: :bold }
      text "#{simbolo}#{format('%.2f', @order.total || 0)}", align: :right, style: :bold
    end

    move_down 6
  end

  def codigo_de_barras
    codigo = @order.respond_to?(:codigo_orden) && @order.codigo_orden.present? ? @order.codigo_orden : @order.numero_orden.to_s
    return if codigo.blank?

    begin
      barcode = Barby::Code128B.new(codigo)
      png_data = Barby::PngOutputter.new(barcode).to_png
      png_io = StringIO.new(png_data)

      image png_io, width: 130, height: 26, position: :center
      move_down 2
      text codigo, size: 6.5, align: :center, character_spacing: 1
      move_down 6
    rescue StandardError => e
      Rails.logger.error("Error al generar código de barras en ticket: #{e.message}")
    end
  end

  def pie_de_pagina
    stroke_horizontal_rule
    move_down 4
    text "¡Gracias por su preferencia!", size: 7, style: :bold, align: :center
    text "Conserve este ticket para cualquier reclamo", size: 6, align: :center, color: "555555"
  end
end