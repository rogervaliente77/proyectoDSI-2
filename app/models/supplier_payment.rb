# app/models/supplier_payment.rb
class SupplierPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, type: Float
  field :payment_date, type: Date
  field :payment_method, type: String
  field :reference_number, type: String
  field :notes, type: String
  field :created_by, type: BSON::ObjectId

  embedded_in :supplier_invoice

  validates :amount, :payment_date, :payment_method, presence: true
  validates :amount, numericality: { greater_than: 0 }

  after_create :update_invoice_balance_and_status
  after_create :registrar_movimiento_caja

  after_destroy :update_invoice_balance_and_status
  after_destroy :revertir_movimiento_caja

  private

  def update_invoice_balance_and_status
    return unless supplier_invoice.present?
    supplier_invoice.save!
  end

  # app/models/supplier_payment.rb
  def registrar_movimiento_caja
    inv = supplier_invoice
    prov = inv&.supplier

    concepto_descripcion = if inv.is_credit?
                            "Abono a Factura N° #{inv.invoice_number} [#{inv.voucher_number}] - Proveedor: #{prov&.name}"
                          else
                            "Pago Factura de Contado N° #{inv.invoice_number} [#{inv.voucher_number}] - Proveedor: #{prov&.name}"
                          end

    # Calcula la distribución fiscal del abono basándose en la factura
    ratio = inv.total_amount.positive? ? (amount / inv.total_amount) : 1.0
    gravado_pago = (inv.total_gravado * ratio).round(2)
    exento_pago = (inv.total_exento * ratio).round(2)
    no_sujeta_pago = (inv.total_no_sujeta * ratio).round(2)

    # 1. Crear el Encabezado de Movimiento de Caja
    head = HeadMovimientoCaja.create!(
      comprobante_codigo: inv.voucher_number,
      origen_tipo: "PagoProveedor",
      origen_id: self.id,
      fecha: payment_date || Time.current,
      monto_total: amount,
      total_gravado: gravado_pago,
      total_exento: exento_pago,
      total_no_sujeta: no_sujeta_pago,
      client_name: prov&.name,
      num_documento_cliente: prov.try(:nit) || prov.try(:dui) || prov.try(:nrc),
      nrc_cliente: prov.try(:nrc),
      email_cliente: prov.try(:email),
      telefono_cliente: prov.try(:phone),
      direccion_cliente: prov.try(:address),
      user_id: created_by,
      supplier_invoice_id: inv.id,
      tipo_documento_dte_id: inv.try(:tipo_documento_dte_id)
    )

    # 2. Crear la única línea de detalle usando los campos reales de DetMovimientoCaja
    head.det_movimientos_caja.create!(
      item_nombre: notes.presence || concepto_descripcion, # <--- CAMBIADO DE 'descripcion' A 'item_nombre'
      tipo_item: "servicio",                              # O el valor por defecto que prefieras
      cantidad: 1.0,
      precio_unitario: amount,
      descuento: 0.0,
      condicion_tributaria: inv.tax_condition.presence || "gravado", # Hereda la condición de la factura
      subtotal: amount
    )
  end

  def revertir_movimiento_caja
    HeadMovimientoCaja.where(origen_tipo: "PagoProveedor", origen_id: self.id).destroy_all
  end
end