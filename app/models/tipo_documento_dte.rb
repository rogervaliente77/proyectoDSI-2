class TipoDocumentoDte
  include Mongoid::Document
  include Mongoid::Timestamps

  field :codigo, type: String  # Ej: "01", "03", "05", "14"
  field :name, type: String  # Ej: "Factura Electrónica", "Comprobante de Crédito Fiscal"
  field :activo, type: Boolean, default: true

  validates :codigo, presence: true, uniqueness: true
  validates :name, presence: true

  # Método para cargar los tipos oficiales si la colección está vacía
  def self.seed_dtes!
    dtes = [
      { codigo: "00", name: "Recibo sin factura electronica" },
      { codigo: "01", name: "Factura Electrónica (FE)" },
      { codigo: "03", name: "Comprobante de Crédito Fiscal Electrónico (CCFE)" },
      { codigo: "05", name: "Nota de Crédito Electrónica (NCE)" },
      { codigo: "06", name: "Nota de Débito Electrónica (NDE)" },
      { codigo: "11", name: "Factura de Exportación Electrónica (FEX)" },
      { codigo: "14", name: "Sujeto Excluido Electrónico (FSEE)" }
    ]

    dtes.each do |dte|
      find_or_create_by(codigo: dte[:codigo]) do |doc|
        doc.name = dte[:name]
        doc.activo = true
      end
    end
  end
end