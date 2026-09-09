class PaymentInstallment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :number, type: Integer
  field :due_date, type: Date
  field :amount, type: Float, default: 0.0
  field :paid_amount, type: Float, default: 0.0

  embedded_in :supplier_invoice

  def balance
    (amount.to_f - paid_amount.to_f).round(2)
  end

  # Estado dinámico de la cuota en tiempo real
  def date_status
    return "pagada" if balance <= 0

    today = Date.today

    if due_date.present? && due_date < today
      "vencida"
    elsif due_date.present? && due_date <= (today + 10.days)
      "proxima_vencer"
    else
      "al_dia"
    end
  end

  def payment_status
    if balance <= 0
      "pagada"
    elsif paid_amount > 0
      "parcial"
    else
      "pendiente"
    end
  end
end