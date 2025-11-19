class Client
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :first_name, type: String
  field :second_name, type: String
  field :email, type: String
  field :phone_number, type: String
  field :main_address, type: String
  field :first_address, type: String
  field :second_address, type: String
  field :third_address, type: String
  field :code, type: String
  field :giro, type: String
  field :nit, type: String
  field :dui, type: String
  field :fecha_registro, type: DateTime
  field :categoria_mora, type: String

  # Validaciones
  validates :name, presence: { message: "El nombre es obligatorio" }, uniqueness: { message: "Este nombre ya existe" }

end
