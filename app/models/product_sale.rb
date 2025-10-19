class ProductSale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :quantity, type: Integer
  field :unit_price, type: Float
  field :discount, type: Float
  field :subtotal, type: Float
  field :offer_type, type: String
  field :concepto, type: String


  # Callbacks — se ejecutan en orden
  before_create :create_product_history
  before_create :update_product_stock

  # Relaciones
  belongs_to :sale
  belongs_to :product

  # Índices
  index({ sale_id: 1 })
  index({ product_id: 1 })

  def update_product_stock
    product = self.product 
    product.quantity = product.quantity - self.quantity 
    product.save
  end

  def create_product_history
    ProductHistory.create!(
      product_id: product.id,
      name: product.name,
      description: product.description,
      quantity: quantity,
      price: unit_price,
      code: product.code,
      discount: discount || 0,
      cash_in: (unit_price - (unit_price * (discount.to_f / 100))) * quantity,
      sale_id: sale.id,
      stock_before: product.quantity,
      current_stock: product.quantity - quantity
    )
  end

  def product_name
    "#{product&.name || 'Producto'} (Cantidad: #{quantity})"
  end
end
