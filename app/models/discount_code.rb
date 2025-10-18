class DiscountCode
  include Mongoid::Document
  include Mongoid::Timestamps

  field :value, type: String
  field :discount, type: Integer
  field :due_date, type: DateTime
  field :product_id, type: BSON::ObjectId

  has_many :sales

  # 🔹 RELACIÓN CON PRODUCT
  belongs_to :product, optional: true

  validates :value, uniqueness: { message: "El código ya existe" }

  before_create :generate_code

  private

  def generate_code
    self.value ||= SecureRandom.alphanumeric(8).upcase
  end
end
