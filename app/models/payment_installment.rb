class PaymentInstallment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :number, type: Integer
  field :due_date, type: Date
  field :amount, type: Float, default: 0.0
  field :paid_amount, type: Float, default: 0.0
  # Estados válidos para cuota: 'pendiente', 'parcial', 'proxima_vencer', 'vencida', 'pagada'
  field :status, type: String, default: "pendiente"

  embedded_in :supplier_invoice

  def balance
    (amount.to_f - paid_amount.to_f).round(2)
  end

  def update_status!
    today = Date.today

    if balance <= 0
      self.status = "pagada"
    elsif paid_amount > 0
      self.status = "parcial"
    elsif due_date.present? && due_date < today
      self.status = "vencida"
    elsif due_date.present? && due_date <= (today + 5.days)
      self.status = "proxima_vencer"
    else
      self.status = "pendiente"
    end
  end
end