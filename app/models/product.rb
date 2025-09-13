# app/models/product.rb
class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,        type: String
  field :description, type: String
  field :quantity,    type: Integer
  field :price,       type: Float
  field :code,        type: String

  has_many :product_sales, dependent: :destroy
  belongs_to :category
  belongs_to :marca #relacion

  embeds_many :product_images
  accepts_nested_attributes_for :product_images, allow_destroy: true

  validates :name, :price, :quantity, presence: true
  validate :unique_image_indexes

  before_create :generate_code

  private

  def generate_code
    return unless category.present?

    prefix   = category.name[0, 3].upcase
    date_str = Date.today.strftime("%Y%m%d")
    count_today = Product.where(
      :created_at.gte => Date.today.beginning_of_day,
      :created_at.lt  => Date.today.end_of_day,
      category_id: category.id
    ).count

    sequence   = count_today + 1
    padded_seq = sequence.to_s.rjust(3, '0')
    self.code = "#{prefix}-#{date_str}-#{padded_seq}"
  end
  
  def unique_image_indexes
    indexes = product_images.map(&:image_index).compact
    if indexes.size != indexes.uniq.size
      errors.add(:product_images, "tienen índices duplicados")
    end
  end
end
