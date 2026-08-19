class Supplier
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String                 # Nombre comercial (ej. Super Repuestos)
  field :business_name, type: String        # Razón social
  field :nit_nrc, type: String              # NIT / NRC / Tax ID
  field :phone, type: String                # Teléfono principal
  field :email, type: String                # Correo de contacto
  field :address, type: String              # Dirección física
  field :contact_person, type: String       # Nombre del vendedor / asesor asignado
  
  # Condiciones de crédito predeterminadas
  field :credit_days, type: Integer, default: 30       # Días de crédito estándar (ej. 15, 30, 60 días)
  field :credit_limit, type: Float, default: 0.0       # Límite de crédito otorgado
  field :active, type: Boolean, default: true

  # Relaciones
  has_many :supplier_invoices, dependent: :restrict_with_error

  # Validaciones
  validates :name, presence: true, uniqueness: true
  
  # Métodos de apoyo
  def total_debt
    # select opera sobre el array en memoria sin ir a MongoDB
    supplier_invoices.select { |inv| %w[pendiente vencida].include?(inv.status) && inv.balance.present? }
                    .sum(&:balance)
  end
end