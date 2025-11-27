class ProductService
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :name, type: String
  field :precio, type: Float
  field :discount, type: Float
  field :description, type: String
  field :start_date, type: Date
  field :end_date, type: Date

  # Un rol puede tener muchos usuarios
  has_many :clients, class_name: "Client", inverse_of: :role

  # Validaciones
  validates :name, presence: { message: "El nombre del servicio es obligatorio" }

end