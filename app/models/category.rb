# app/models/category.rb
class Category
  include Mongoid::Document
  include Mongoid::Timestamps  # crea created_at y updated_at automáticamente

  # Campos
  field :name,        type: String
  field :description, type: String

  # Relaciones
  has_many :products, class_name: "Product", inverse_of: :category, dependent: :destroy

  # Validaciones
  validates :name, presence: true, uniqueness: true
end
