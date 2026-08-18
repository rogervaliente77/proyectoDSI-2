class SupplierInvoice
  include Mongoid::Document
  include Mongoid::Timestamps

  # Datos de la Factura / Comprobante
  field :invoice_number, type: String        # Número de Factura física/digital
  field :voucher_number, type: String        # Número de Comprobante / Registro interno
  field :voucher_type, type: String, default: "ccf" # ccf, factura, nota_credito, etc.
  field :description, type: String           # Detalle general del pedido/repuestos

  # Fechas clave
  field :issue_date, type: Date              # Fecha de emisión de la factura
  field :due_date, type: Date                # Fecha de vencimiento
  field :payment_date, type: Date            # Fecha en que se liquidó por completo

  # Montos Financieros
  field :total_amount, type: Float, default: 0.0     # Monto total de la factura
  field :paid_amount, type: Float, default: 0.0      # Total que se ha pagado/abonado
  field :balance, type: Float, default: 0.0          # Cuánto falta por pagar (Saldo pendiente)

  # Estado del Crédito/Factura
  # Opciones: 'pendiente', 'pagada', 'vencida', 'anulada'
  field :status, type: String, default: "pendiente"

  # Relaciones
  belongs_to :supplier
  embeds_many :supplier_payments                   # Historial de abonos/pagos recibidos

  # Validaciones
  validates :invoice_number, :issue_date, :due_date, :total_amount, presence: true
  validates :total_amount, numericality: { greater_than: 0 }

  # Callbacks para mantener saldos y estados sincronizados
  before_save :calculate_balance_and_status

  # Scopes útiles para consultas
  scope :pending, -> { where(status: "pendiente") }
  scope :overdue, -> { where(status: "vencida") }
  scope :paid, -> { where(status: "pagada") }

  # Métodos auxiliares
  def days_until_due
    return 0 if due_date.blank?
    (due_date - Date.today).to_i
  end

  def is_overdue?
    balance > 0 && due_date < Date.today
  end

  private

  def calculate_balance_and_status
    # Recalcula el total abonado basado en los pagos embebidos
    self.paid_amount = supplier_payments.sum(:amount)
    self.balance = (total_amount - paid_amount).round(2)

    if balance <= 0
      self.balance = 0.0
      self.status = "pagada"
      self.payment_date ||= Date.today
    elsif due_date.present? && due_date < Date.today
      self.status = "vencida"
    else
      self.status = "pendiente"
    end
  end
end