class ProductSale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :quantity, type: Integer
  field :unit_price, type: Float
  field :discount, type: Float
  field :subtotal, type: Float


  before_create :update_product_stock

  # Relaciones
  belongs_to :sale
  belongs_to :product

  # Índices para mejorar rendimiento de búsquedas
  index({ sale_id: 1 })
  index({ product_id: 1 })

  def update_product_stock
    product = self.product

    product.quantity = product.quantity - self.quantity

    product.save
  end
end
