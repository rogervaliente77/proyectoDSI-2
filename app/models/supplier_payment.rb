class SupplierPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :payment_date, type: Date, default: -> { Date.today } # Fecha del abono
  field :amount, type: Float, default: 0.0                    # Monto abonado
  field :payment_method, type: String, default: "transferencia" # efectivo, transferencia, cheque, tarjeta
  field :reference_number, type: String                       # Número de cheque / transacción
  field :notes, type: String                                  # Observaciones / Notas

  embedded_in :supplier_invoice

  validates :amount, presence: true, numericality: { greater_than: 0 }
end