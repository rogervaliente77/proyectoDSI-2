class Sucursal
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :codigo, type: String # Formato de 4 o 2 caracteres según estándar MH (ej. "0000" / "00" para Matriz, "0001" / "01" para Sucursal 1)

  has_many :cajas
  has_many :cajeros

  validates :name, presence: true
  validates :codigo, presence: true, uniqueness: true, format: { with: /\A\d{2,4}\z/, message: "debe ser numérico (ej. 00, 01, 0000)" }

  # Muestra ej: "Matriz (00)" o "Sucursal 1 (01)"
  def display_name
    "#{name} (#{codigo})"
  end
end