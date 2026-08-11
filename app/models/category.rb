# app/models/category.rb
class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  # -------- CAMPOS --------
  field :name,        type: String
  field :description, type: String

  # -------- RELACIONES AUTORREFERENCIALES --------
  # Categoría Padre (opcional: si es nil, es una categoría raíz/principal como "Repuestos")
  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :subcategories

  # Subcategorías Hijas (ej: "Suspensión y Dirección", "Sistema de Frenos")
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  # Productos
  has_many :products, class_name: "Product", inverse_of: :category, dependent: :destroy

  # -------- VALIDACIONES --------
  validates :name, presence: true
  # Validamos unicidad del nombre solo en el mismo nivel (dos subcategorías del mismo padre no pueden llamarse igual)
  validates :name, uniqueness: { scope: :parent_id, message: "ya existe en este nivel de categoría" }
  validate :cannot_be_own_parent

  # -------- SCOPES --------
  # Permite obtener solo las categorías principales (sin padre)
  scope :main_categories, -> { where(parent_id: nil) }

  # -------- MÉTODOS HELPER --------
  # Devuelve true si es una categoría principal
  def main?
    parent_id.nil?
  end

  # Devuelve true si es una subcategoría
  def subcategory?
    parent_id.present?
  end

  # Devuelve el nombre completo jerárquico (ej: "Repuestos > Suspensión y Dirección")
  def full_name
    parent ? "#{parent.name} > #{name}" : name
  end

  private

  # Evita que una categoría sea su propia categoría padre
  def cannot_be_own_parent
    if parent_id.present? && parent_id == id
      errors.add(:parent_id, "no puede ser padre de sí misma")
    end
  end
end