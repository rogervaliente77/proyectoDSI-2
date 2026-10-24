class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include Auditable

  # -------- CAMPOS --------
  field :name,             type: String
  field :description,      type: String
  field :quantity,         type: Integer
  field :price,            type: Float
  field :cost_price,       type: Float
  field :code,             type: String
  field :discount,         type: Integer, default: 0
  field :offer_type,       type: String
  field :offer_expires_at, type: DateTime
  field :wholesale_quantity, type: Integer
  field :wholesale_price, type: Float
  field :kind, type: String, default: "producto"

  # Atributo virtual para capturar el usuario actual en peticiones web
  attr_accessor :current_user_id, :stock_before_update, :price_before_update

  # -------- RELACIONES --------
  has_many :product_sales, dependent: :destroy
  belongs_to :category
  belongs_to :supplier, optional: true
  belongs_to :marca, optional: true
  belongs_to :car_type, optional: true
  belongs_to :offer, optional: true

  embeds_many :product_images
  accepts_nested_attributes_for :product_images, allow_destroy: true

  # -------- VALIDACIONES --------
  validates :kind, presence: true, inclusion: { in: %w[producto servicio] }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :producto?
  validates :marca, presence: true, if: :producto?
  validate :unique_image_indexes

  # -------- CALLBACKS --------
  before_create :generate_code
  after_find :check_offer_expiration

  # Callbacks para registrar el historial de inventario de forma automática
  after_create :create_initial_history
  
  # Capturamos los valores previos antes de actualizar
  before_update :capture_previous_values
  after_update :create_update_history

  # -------- MÉTODOS DE OFERTA --------
  def on_offer?
    offer.present? && (offer_expires_at.nil? || offer_expires_at.future?)
  end

  def discount_percentage
    on_offer? && offer.descuento? ? offer.discount_percentage.to_i : 0
  end

  def offer_type
    on_offer? ? offer.offer_type : nil
  end

  def discounted_price
    return price unless on_offer? && offer.descuento? && discount_percentage > 0
    price - (price * (discount_percentage / 100.0))
  end

  def current_price
    discounted_price
  end

  def discount_amount
    price - discounted_price
  end

  def discount_decimal
    discount.to_f / 100.0
  end

  # -------- STOCK --------
  def low_stock?
    producto? && quantity.present? && quantity < 15
  end

  def stock_status
    return "Servicio Activo" if servicio?
    return "Agotado" if quantity.to_i == 0
    return "Stock bajo (#{quantity})" if low_stock?

    "En stock (#{quantity})"
  end

  def servicio?
    kind == "servicio"
  end

  def producto?
    kind == "producto"
  end

  def category_full_name
    category&.full_name || "Sin Categoría"
  end
  
  def main_category
    category&.parent || category
  end

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
    self.code  = "#{prefix}-#{date_str}-#{padded_seq}"
  end

  def check_offer_expiration
    return unless offer_expires_at.present? && offer_expires_at.to_date < Date.current

    self.discount = 0
    self.offer_type = nil
    save! if changed?
  end

  def unique_image_indexes
    indexes = product_images.map(&:image_index).compact
    if indexes.size != indexes.uniq.size
      errors.add(:product_images, "tienen índices duplicados")
    end
  end

  # --- LÓGICA DE HISTORIAL AUTOMÁTICA ---
  def create_initial_history
    initial_qty = producto? ? quantity.to_i : 0
    
    ProductHistory.create!(
      product: self,
      name: self.name,
      description: self.description,
      code: self.code,
      quantity: initial_qty,
      price: self.price,
      discount: self.discount,
      stock_before: 0,
      current_stock: initial_qty,
      movement_type: "1", # 1 = Entrada
      concepto: "Carga inicial por creación de producto",
      user_id: self.current_user_id
    )
  end

  def capture_previous_values
    self.stock_before_update = self.quantity_was.to_i
    self.price_before_update = self.price_was.to_f
  end

  def create_update_history
    # 1. Movimiento de stock para productos físicos
    if producto? && saved_change_to_attribute?(:quantity)
      stock_after = self.quantity.to_i
      stock_before = stock_before_update.to_i

      if stock_after != stock_before
        # Evaluamos exactamente como lo hacías en el controlador: Mayor a antes es "1" (Ingreso), de lo contrario "2" (Egreso)
        movement_type = stock_after > stock_before ? "1" : "2"
        diff = (stock_after - stock_before).abs

        concepto_texto = movement_type == "1" ? "Ingreso de inventario por actualización de producto" : "Egreso de inventario por ajuste en edición"

        ProductHistory.create!(
          product: self,
          name: self.name,
          description: self.description,
          code: self.code,
          quantity: diff,
          price: self.price,
          discount: self.discount,
          stock_before: stock_before,
          current_stock: stock_after,
          movement_type: movement_type,
          concepto: concepto_texto,
          user_id: self.current_user_id
        )
      end

    # 2. Movimiento por cambio de tarifa para servicios
    elsif servicio? && saved_change_to_attribute?(:price)
      old_p = price_before_update
      new_p = self.price.to_f

      if old_p != new_p
        ProductHistory.create!(
          product: self,
          name: self.name,
          description: self.description,
          code: self.code,
          quantity: 0,
          price: new_p,
          discount: self.discount,
          stock_before: nil,
          current_stock: nil,
          movement_type: "Ajuste",
          concepto: "Ajuste de tarifa en edición de servicio ($#{old_p} -> $#{new_p})",
          user_id: self.current_user_id
        )
      end
    end
  end
end