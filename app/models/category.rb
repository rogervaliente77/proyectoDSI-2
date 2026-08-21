# app/models/category.rb
class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  # -------- CAMPOS --------
  field :name,        type: String
  field :description, type: String
  field :image_url,   type: String

  # Atributo virtual para recibir el archivo
  attr_accessor :image_file

  # -------- CALLBACKS DE CLOUDINARY --------
  before_validation :process_cloudinary_upload, if: -> { image_file.present? }
  after_destroy :delete_cloudinary_image, if: -> { image_url.present? }

  # -------- RELACIONES AUTORREFERENCIALES --------
  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :subcategories
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :products, class_name: "Product", inverse_of: :category, dependent: :destroy

  # -------- VALIDACIONES --------
  validates :name, presence: true
  validates :name, uniqueness: { scope: :parent_id, message: "ya existe en este nivel de categoría" }
  validate :cannot_be_own_parent

  # -------- SCOPES --------
  scope :main_categories, -> { where(parent_id: nil) }

  # -------- MÉTODOS HELPER --------
  def main?
    parent_id.nil?
  end

  def subcategory?
    parent_id.present?
  end

  def full_name
    parent ? "#{parent.name} > #{name}" : name
  end

  def ancestor_path
    ancestors = []
    current = self
    while current
      ancestors.unshift(current.name)
      current = current.parent
    end
    ancestors.join(" > ")
  end

  # Helper estático para obtener todas las categorías formateadas excluyendo una específica (y sus descendientes)
  def self.options_for_select(excluded_category = nil)
    categories = all.to_a
    
    if excluded_category.present? && excluded_category.persisted?
      # Excluye la categoría actual para que no sea su propio padre
      categories.reject! { |c| c.id == excluded_category.id }
    end

    # Ordena alfabéticamente por la ruta completa
    categories.sort_by(&:ancestor_path).map do |cat|
      [cat.ancestor_path, cat.id]
    end
  end

  def self_and_descendant_ids
    ids = [self.id]
    subcategories.each do |subcat|
      ids.concat(subcat.self_and_descendant_ids)
    end
    ids
  end

  private

  def cannot_be_own_parent
    return if parent_id.blank?

    if parent_id == id
      errors.add(:parent_id, "no puede ser padre de sí misma")
      return
    end

    # Verifica que el nuevo padre no sea un descendiente directo/indirecto
    current_parent = parent
    while current_parent
      if current_parent.id == id
        errors.add(:parent_id, "no puede ser una subcategoría perteneciente a esta misma categoría")
        break
      end
      current_parent = current_parent.parent
    end
  end

  # Procesa la subida a Cloudinary, destruye la imagen previa si existía y fija un timeout de 2 minutos (120 s)
  def process_cloudinary_upload
    upload_path = image_file.respond_to?(:tempfile) ? image_file.tempfile.path : image_file.path

    # 1. Si ya tiene una imagen asociada, la borramos para evitar duplicados en la nube
    delete_cloudinary_image if image_url.present?

    # 2. Subida sincrónica con timeout de 120 segundos
    result = Cloudinary::Uploader.upload(
      upload_path,
      folder: "categories",
      timeout: 120
    )

    self.image_url = result["secure_url"]
  rescue Faraday::TimeoutError, Net::ReadTimeout
    errors.add(:image_file, "El tiempo de subida expiró (máximo 2 minutos). Intenta con una imagen más liviana.")
  rescue StandardError => e
    errors.add(:image_file, "No se pudo subir la imagen a Cloudinary: #{e.message}")
  end

  # Elimina el archivo de Cloudinary extrayendo su public_id desde la URL
  def delete_cloudinary_image
    public_id = extract_cloudinary_public_id(image_url)
    return unless public_id.present?

    Cloudinary::Uploader.destroy(public_id)
  rescue StandardError => e
    Rails.logger.error("Error al eliminar imagen de Cloudinary (#{image_url}): #{e.message}")
  end

  # Helper para obtener el public_id completo (incluyendo carpetas) desde una URL de Cloudinary
  def extract_cloudinary_public_id(url)
    return nil if url.blank?

    # Extrae el path posterior a '/upload/' o '/upload/v12345/'
    uri_path = URI.parse(url).path
    match = uri_path.match(%r{/upload/(?:v\d+/)?(.+)\.[a-z]+$}i)
    match ? match[1] : nil
  end
end