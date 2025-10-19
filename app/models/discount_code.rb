# app/models/discount_code.rb
class DiscountCode
  include Mongoid::Document
  include Mongoid::Timestamps

  field :value, type: String
  field :discount, type: Integer
  field :due_date, type: DateTime
  field :offer_expires_at, type: DateTime   # <-- agregado para compatibilidad con la vista
  field :product_id, type: BSON::ObjectId

  has_many :sales

  # 🔹 RELACIÓN CON PRODUCT
  belongs_to :product, optional: true

  validates :value, uniqueness: { message: "El código ya existe" }

  before_create :generate_code

  # Método opcional para limpiar ofertas expiradas
  def check_offer_expiration
    return unless offer_expires_at.present? && offer_expires_at.past?

    self.discount = 0
    self.offer_type = nil if respond_to?(:offer_type) # evita errores si no existe
  end

  private

  def generate_code
    self.value ||= SecureRandom.alphanumeric(8).upcase
  end
end
