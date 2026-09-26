class Sale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sold_at, type: DateTime
  field :client_name, type: String              # Permite digitación manual o autocompletada
  field :status, type: String, default: "completed"
  field :total_amount, type: Float
  field :code, type: String
  field :tipo_impuesto, type: String, default: "gravado"

  field :delivery_method, type: String
  field :was_delivered, type: Boolean, default: false
  field :delivered_at, type: DateTime

  field :condicion_tributaria, type: String, default: "gravado" # <-- Agrega esta línea
  field :tipo_impuesto, type: String, default: "gravado"

  # Relaciones
  belongs_to :client, optional: true           # Opcional para externas/público general
  belongs_to :sucursal, optional: true
  belongs_to :tipo_documento_dte, class_name: "TipoDocumentoDte", optional: true
  belongs_to :caja, class_name: "Caja", inverse_of: :sales, optional: true
  belongs_to :cajero, class_name: "Cajero", inverse_of: :sales, optional: true
  belongs_to :user, optional: true

  has_many :product_sales, class_name: "ProductSale", inverse_of: :sale, dependent: :destroy
  has_many :devoluciones, class_name: "Devolucion", inverse_of: :sale, dependent: :destroy
  has_one :head_movimiento_caja, class_name: "HeadMovimientoCaja", dependent: :nullify
  has_one :delivery

  accepts_nested_attributes_for :product_sales, allow_destroy: true
  validates :code, uniqueness: true, allow_blank: true

  before_create :set_defaults

  private

  def set_defaults
    self.sold_at ||= Time.current
    generate_internal_code
  end

  def generate_internal_code
    return if code.present?

    prefix = 'V'
    date_str = Date.today.strftime("%Y-%m-%d")
    count_today = Sale.where(
      :created_at.gte => Date.today.beginning_of_day,
      :created_at.lt  => Date.today.end_of_day
    ).count

    self.code = "#{prefix}-#{date_str}-#{(count_today + 1).to_s.rjust(3, '0')}"
  end
end