class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  # -------- CAMPOS --------
  field :name,             type: String
  field :description,      type: String
  field :quantity,         type: Integer
  field :price,            type: Float
  field :code,             type: String
  field :discount,         type: Integer, default: 0
  field :offer_type,       type: String # "descuento", "2x1", "mayoreo"
  field :offer_expires_at, type: DateTime

  # -------- RELACIONES --------
  has_many :product_sales, dependent: :destroy
  belongs_to :category
  belongs_to :marca

  embeds_many :product_images
  accepts_nested_attributes_for :product_images, allow_destroy: true

  # -------- VALIDACIONES --------
  validates :name, :price, :quantity, presence: true
  validate :unique_image_indexes

  # -------- CALLBACKS --------
  before_create :generate_code
  after_find :check_offer_expiration

  # -------- MÉTODOS DE OFERTA --------

  # Devuelve true si el producto está actualmente en oferta
  def on_offer?
    (discount.to_i > 0 || offer_type.present?) && (offer_expires_at.nil? || offer_expires_at.future?)
  end

  # Precio descontado
  def discounted_price
    return price if discount.to_i.zero?
    price - (price * discount / 100.0)
  end

  # Precio actual considerando descuento
  def current_price
    return price unless on_offer?

    if offer_type == "descuento" && discount.to_i > 0
      discounted_price
    else
      price
    end
  end

  # Monto del descuento
  def discount_amount
    price - discounted_price
  end

  # Descuento en decimal
  def discount_decimal
    discount.to_f / 100.0
  end

  # -------- STOCK --------
  def low_stock?
    quantity.present? && quantity < 25
  end

  def stock_status
    if quantity.to_i == 0
      "Agotado"
    elsif low_stock?
      "Stock bajo (#{quantity})"
    else
      "En stock (#{quantity})"
    end
  end

  # -------- CALLBACKS --------
  private

  # Genera código único por categoría y día
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

  # Verifica si la oferta ha expirado y la limpia
  def check_offer_expiration
    return unless offer_expires_at.present? && offer_expires_at.past?

    self.discount = 0
    self.offer_type = nil
    save! if changed?
  end

  # Valida que las imágenes no tengan índices duplicados
  def unique_image_indexes
    indexes = product_images.map(&:image_index).compact
    if indexes.size != indexes.uniq.size
      errors.add(:product_images, "tienen índices duplicados")
    end
  end
end
