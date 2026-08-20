# app/models/supplier_payment.rb
class SupplierPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos propios del pago
  field :amount, type: Float
  field :payment_date, type: Date
  field :payment_method, type: String
  field :reference_number, type: String
  field :notes, type: String

  # Guardamos únicamente el ObjectId del usuario que crea el registro
  field :created_by, type: BSON::ObjectId

  # Relación con la factura (subdocumento embebido)
  embedded_in :supplier_invoice

  # Validaciones
  validates :amount, :payment_date, :payment_method, presence: true
  validates :amount, numericality: { greater_than: 0 }

  # Callbacks
  after_create :update_invoice_balance_and_status
  after_destroy :update_invoice_balance_and_status

  private

  def update_invoice_balance_and_status
    return unless supplier_invoice.present?

    # Guardar el documento padre dispara automáticamente el callback 'before_save :recalculate_and_sync_credit'
    # en SupplierInvoice, lo que recalcula saldos, distribuye abonos en las cuotas y actualiza los estados.
    supplier_invoice.save!
  end
end