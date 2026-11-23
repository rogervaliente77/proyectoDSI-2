class HeaderSlide
  include Mongoid::Document
  include Mongoid::Timestamps

  field :image_url, type: String
  field :public_id, type: String
  field :position, type: Integer, default: 0

  # Campos dinámicos para el Slider
  field :badge_text, type: String
  field :title_part1, type: String
  field :title_part2, type: String
  field :description, type: String

  # Colores configurables por lámina
  field :badge_bg_color, type: String, default: "#0d6efd"
  field :badge_text_color, type: String, default: "#ffffff"
  field :title_part1_color, type: String, default: "#ffffff"
  field :title_part2_color, type: String, default: "#ffc532"
  field :description_color, type: String, default: "#f8f9fa"

  embedded_in :site_configuration

  before_destroy :destroy_cloudinary_image

  default_scope -> { order_by(position: :asc) }

  private

  def destroy_cloudinary_image
    return if public_id.blank?

    begin
      Cloudinary::Uploader.destroy(public_id)
    rescue StandardError => e
      Rails.logger.error("Error al eliminar la imagen #{public_id} de Cloudinary: #{e.message}")
    end
  end
end