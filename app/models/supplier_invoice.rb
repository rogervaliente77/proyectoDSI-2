# app/models/supplier_invoice.rb
class SupplierInvoice
  include Mongoid::Document
  include Mongoid::Timestamps

  # Datos de Factura
  field :invoice_number, type: String   # Número impreso por el proveedor
  field :voucher_number, type: String   # Código interno automático (FAC-XXXXXXX)
  field :voucher_type, type: String, default: "ccf"
  field :description, type: String

  # Clasificación Tributaria de la Compra
  field :tax_condition, type: String # "gravado", "exento", "no_sujeta"
  field :total_gravado, type: Float, default: 0.0
  field :total_exento, type: Float, default: 0.0
  field :total_no_sujeta, type: Float, default: 0.0

  # Fechas clave
  field :issue_date, type: Date
  field :due_date, type: Date
  field :payment_date, type: Date

  # Parámetros del Crédito
  field :is_credit, type: Boolean, default: true
  field :credit_term_days, type: Integer, default: 30
  field :installments_count, type: Integer, default: 1
  field :interest_rate, type: Float, default: 0.0
  field :term_type, type: String, default: "mensual"
  field :payment_day, type: Integer

  # Montos Financieros
  field :total_amount, type: Float, default: 0.0
  field :paid_amount, type: Float, default: 0.0
  field :balance, type: Float, default: 0.0

  # Relaciones
  belongs_to :supplier
  embeds_many :supplier_payments, class_name: "SupplierPayment"
  embeds_many :payment_installments, class_name: "PaymentInstallment"
  embeds_many :status_histories, class_name: "StatusHistory"

  # Validaciones
  validates :invoice_number, :issue_date, :total_amount, presence: true
  validates :total_amount, numericality: { greater_than: 0 }

  # Callbacks
  before_validation :generate_internal_voucher_number, on: :create
  before_save :calculate_tax_totals
  before_save :recalculate_and_sync_credit
  after_create :generate_installments_plan!
  after_create :procesar_pago_contado_inicial

  def date_status
    return "pagada" if balance <= 0

    today = Date.today

    if payment_installments.any? { |i| i.date_status == "vencida" } || (due_date.present? && due_date < today)
      "vencida"
    elsif payment_installments.any? { |i| i.date_status == "proxima_vencer" } || (due_date.present? && due_date <= (today + 10.days))
      "proxima_vencer"
    else
      "al_dia"
    end
  end

  def payment_status
    if balance <= 0
      "pagada"
    elsif paid_amount > 0
      "pago_parcial"
    else
      "sin_pago"
    end
  end

  def status
    payment_status
  end

  def overdue?
    date_status == "vencida"
  end

  def paid?
    balance <= 0
  end

  def partially_paid?
    paid_amount > 0 && balance > 0
  end

  def generate_installments_plan!
    return unless is_credit && installments_count.to_i > 0

    payment_installments.destroy_all
    installment_amount = (total_amount / installments_count).round(2)
    last_amount = (total_amount - (installment_amount * (installments_count - 1))).round(2)

    installments_count.times do |i|
      i_due_date = calculate_installment_due_date(i + 1)

      payment_installments.build(
        number: i + 1,
        due_date: i_due_date,
        amount: (i == installments_count - 1) ? last_amount : installment_amount,
        paid_amount: 0.0
      )
    end

    self.due_date = payment_installments.last&.due_date
    save
  end

  private

  # Genera el código interno único (Ej: FAC-8A3F19X)
  def generate_internal_voucher_number
    return if voucher_number.present?

    loop do
      random_code = SecureRandom.alphanumeric(7).upcase
      self.voucher_number = "FAC-#{random_code}"
      break unless SupplierInvoice.where(voucher_number: self.voucher_number).exists?
    end
  end

  # Desglosa automáticamente el monto según la condición tributaria seleccionada
  def calculate_tax_totals
    case tax_condition
    when "exento"
      self.total_exento = total_amount
      self.total_gravado = 0.0
      self.total_no_sujeta = 0.0
    when "no_sujeta"
      self.total_no_sujeta = total_amount
      self.total_gravado = 0.0
      self.total_exento = 0.0
    else # "gravado" por defecto
      self.total_gravado = total_amount
      self.total_exento = 0.0
      self.total_no_sujeta = 0.0
    end
  end

  def recalculate_and_sync_credit
    self.paid_amount = supplier_payments.sum(&:amount).round(2)
    self.balance = (total_amount - paid_amount).round(2)

    remaining_paid = paid_amount
    payment_installments.order_by(number: :asc).each do |inst|
      if remaining_paid >= inst.amount
        inst.paid_amount = inst.amount
        remaining_paid -= inst.amount
      else
        inst.paid_amount = remaining_paid
        remaining_paid = 0.0
      end
    end
  end

  def calculate_installment_due_date(step)
    base_date = issue_date || Date.today

    case term_type
    when "diario"
      base_date + step.days
    when "semanal"
      base_date + (step * 7).days
    when "mensual", "bimestral", "trimestral", "semestral"
      months_addition = case term_type
                        when "mensual"   then step * 1
                        when "bimestral"  then step * 2
                        when "trimestral" then step * 3
                        when "semestral"  then step * 6
                        end

      target_date = base_date >> months_addition

      if payment_day.present? && payment_day.between?(1, 31)
        max_days_in_month = Date.new(target_date.year, target_date.month, -1).day
        day_to_set = [payment_day, max_days_in_month].min
        Date.new(target_date.year, target_date.month, day_to_set)
      else
        target_date
      end
    else
      interval_days = (credit_term_days.to_f / installments_count).round
      base_date + (step * interval_days).days
    end
  end

  def procesar_pago_contado_inicial
    return if is_credit?

    supplier_payments.create!(
      amount: total_amount,
      payment_date: issue_date || Date.today,
      payment_method: "efectivo",
      notes: description.presence || "Pago automático por compra al contado (Factura: #{invoice_number})",
      created_by: self.try(:created_by)
    )
  end
end