# app/models/product_image.rb
class ProductImage
  include Mongoid::Document

  field :title,       type: String
  field :image_url,   type: String
  field :image_index, type: Integer

  embedded_in :product

  validates :image_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "debe ser una URL válida" }
end
