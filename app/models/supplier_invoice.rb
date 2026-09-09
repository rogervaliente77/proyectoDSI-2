class SupplierInvoice
  include Mongoid::Document
  include Mongoid::Timestamps

  # Datos de Factura
  field :invoice_number, type: String
  field :voucher_number, type: String
  field :voucher_type, type: String, default: "ccf"
  field :description, type: String

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
  before_save :recalculate_and_sync_credit
  after_create :generate_installments_plan!

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

  # 2. ESTADO DE PAGO / MONTO
  def payment_status
    if balance <= 0
      "pagada"
    elsif paid_amount > 0
      "pago_parcial"
    else
      "sin_pago"
    end
  end

  # Conservamos tu método 'status' como alias del estado de pago o combinador si lo usas en otros lados
  def status
    payment_status
  end

  # Helpers booleanos para facilitar las vistas
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
end