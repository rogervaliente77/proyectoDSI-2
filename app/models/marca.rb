class Marca
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :name,        type: String
  field :description, type: String

  # Relaciones
  has_many :products, dependent: :destroy

  # Validaciones
  validates :name, presence: true, uniqueness: true
  validates :description, presence: { message: "no puede estar vacía" }, length: { maximum: 500 }
end
