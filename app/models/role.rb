class Role
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :name, type: String
  field :description, type: String

  # Un rol puede tener muchos usuarios
  has_many :users, class_name: "User", inverse_of: :role

  # Validaciones
  validates :name, presence: { message: "El nombre del rol es obligatorio" }, uniqueness: { message: "Este rol ya existe" }

end
