class Offer
  include Mongoid::Document
  include Mongoid::Timestamps

  # -------- CAMPOS --------
  field :name,                type: String # ej. "Descuento de Temporada", "Mayoreo Especial"
  field :offer_type,          type: String # "descuento", "2x1", "3x1", "mayoreo"
  field :discount_percentage, type: Integer, default: 0 # Para tipo "descuento"
  field :active,              type: Boolean, default: true

  # -------- RELACIONES --------
  has_many :products, dependent: :nullify

  # -------- VALIDACIONES --------
  validates :name, presence: true, uniqueness: true
  validates :offer_type, presence: true, inclusion: { in: %w[descuento 2x1 3x1 mayoreo] }
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, if: :descuento?

  # -------- SCOPES / HELPER METHODS --------
  scope :active, -> { where(active: true) }

  def descuento?
    offer_type == "DESCUENTO"
  end

  def mayoreo?
    offer_type == "MAYOREO"
  end

  def display_name
    case offer_type
    when "DESCUENTO"
      "DESCUENTO"
    when "MAYOREO"
      "PRECIO MAYOREO"
    else
      "#{name}"
    end
  end
end