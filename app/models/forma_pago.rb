class FormaPago
  include Mongoid::Document
  include Mongoid::Timestamps

  field :codigo, type: String # Ej: "01", "02", "03" (o slugs como "EFECTIVO", "TARJETA")
  field :name, type: String   # Ej: "Efectivo", "Tarjeta de Débito/Crédito", "Transferencia / Depósito"
  field :activo, type: Boolean, default: true

  validates :codigo, presence: true, uniqueness: true
  validates :name, presence: true

  scope :activos, -> { where(activo: true) }

  def self.seed_formas_pago!
    formas = [
      { codigo: "01", name: "EFECTIVO" },
      { codigo: "02", name: "TARJETA" },
      { codigo: "03", name: "TRANSFERENCIA" },
      { codigo: "04", name: "BITCOIN" },
      { codigo: "05", name: "CHEQUE" }
    ]

    formas.each do |forma|
      find_or_create_by(codigo: forma[:codigo]) do |doc|
        doc.name = forma[:name]
        doc.activo = true
      end
    end
  end
end