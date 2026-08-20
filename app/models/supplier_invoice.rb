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

  # Estados factura: 'pendiente', 'al_dia', 'proxima_vencer', 'vencida', 'pagada', 'anulada'
  field :status, type: String, default: "pendiente"

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

  def change_status!(new_status_val, user_id = nil, reason = nil)
    return if status == new_status_val

    status_histories.build(
      previous_status: status,
      new_status: new_status_val,
      changed_by: user_id,
      reason: reason
    )
    self.status = new_status_val
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
        paid_amount: 0.0,
        status: "pendiente" # Se establece 'pendiente' por defecto
      )
    end

    self.due_date = payment_installments.last&.due_date
    save
  end

  private

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

  def recalculate_and_sync_credit
    # 1. Total pagado calculado desde la colección embebida de pagos
    self.paid_amount = supplier_payments.sum(&:amount).round(2)
    self.balance = (total_amount - paid_amount).round(2)

    # 2. Distribuir el pago acumulado en orden de cuotas
    remaining_paid = paid_amount
    payment_installments.order_by(number: :asc).each do |inst|
      if remaining_paid >= inst.amount
        inst.paid_amount = inst.amount
        remaining_paid -= inst.amount
      else
        inst.paid_amount = remaining_paid
        remaining_paid = 0.0
      end
      inst.update_status!
    end

    # 3. Evaluar el estado global de la factura
    determine_overall_status
  end

  def determine_overall_status
    today = Date.today

    if balance <= 0
      self.balance = 0.0
      self.payment_date ||= today
      change_status!("pagada")
    elsif payment_installments.any? { |i| i.status == "vencida" } || (due_date.present? && due_date < today)
      change_status!("vencida")
    elsif payment_installments.any? { |i| i.status == "proxima_vencer" }
      change_status!("proxima_vencer")
    elsif paid_amount > 0
      change_status!("al_dia")
    else
      change_status!("pendiente")
    end
  end
end