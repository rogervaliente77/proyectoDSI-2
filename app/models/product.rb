class Product
  include Mongoid::Document
  include Mongoid::Timestamps  # añade created_at y updated_at

  # Campos
  field :name,        type: String
  field :description, type: String
  field :quantity,    type: Integer
  field :price,       type: Float
  field :image_url,   type: String
  field :code,        type: String

  # Relaciones
  has_many   :product_sales, dependent: :destroy
  belongs_to :category

  # Validaciones
  validates :name, :price, :quantity, presence: true

  # Callbacks
  before_create :generate_code

  private

  def generate_code
    return unless category.present?

    prefix   = category.name[0, 3].upcase
    date_str = Date.today.strftime("%Y%m%d")

    # Contar productos creados hoy en la misma categoría
    count_today = Product.where(
      :created_at.gte => Date.today.beginning_of_day,
      :created_at.lt  => Date.today.end_of_day,
      category_id: category.id
    ).count

    sequence   = count_today + 1
    padded_seq = sequence.to_s.rjust(3, '0') # "001", "002", etc.

    self.code = "#{prefix}-#{date_str}-#{padded_seq}"
  end
end
