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
  validates :description, length: { maximum: 500 }
end
