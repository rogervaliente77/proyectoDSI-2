# app/models/product_image.rb
class ProductImage
  include Mongoid::Document

  field :title,       type: String
  field :image_url,   type: String
  field :image_index, type: Integer

  embedded_in :product

  attr_accessor :file

  # Usar before_validation garantiza que image_url tenga valor antes de ser validado
  before_validation :upload_to_cloudinary, if: -> { file.present? }

  # Validamos la URL únicamente si está presente para dar flexibilidad
  validates :image_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "debe ser una URL válida" }, allow_blank: true
  
  # En documentos embebidos de Mongoid, uniqueness debe configurarse adecuadamente
  validates :image_index, presence: true

  private

  def upload_to_cloudinary
    # file puede ser un ActionDispatch::Http::UploadedFile, enviamos su tempfile path
    upload_path = file.respond_to?(:tempfile) ? file.tempfile.path : file.path
    result = Cloudinary::Uploader.upload(upload_path, folder: "products")
    self.image_url = result["secure_url"]
  rescue StandardError => e
    errors.add(:file, "no se pudo subir la imagen a Cloudinary: #{e.message}")
  end
end