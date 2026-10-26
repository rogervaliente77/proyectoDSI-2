class ProductSale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :quantity, type: Integer
  field :unit_price, type: Float
  field :discount, type: Float
  field :discount_porcentage, type: Float
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
  # 
  index({ sale_id: 1 })
  index({ product_id: 1 })

  def update_product_stock
    product = self.product
    product.skip_history_callbacks = true
    product.quantity = product.quantity - self.quantity 
    product.save
  end

  def create_product_history
    concepto = "Egreso de inventario por venta realizada #{self.sale.code}"

    ProductHistory.create!(
      product_id: product.id,
      name: product.name,
      description: product.description,
      code: product.code,
      quantity: quantity,
      price: unit_price,
      discount: discount || 0,
      cash_in: (unit_price - (unit_price * (discount.to_f / 100))) * quantity,
      sale_id: sale.id,
      movement_type: "2",
      concepto: concepto,
      stock_before: product.quantity,
      current_stock: product.quantity - quantity,
      user_id: self.sale.user_id
    )
  end

  def product_name
    "#{product&.name || 'Producto'} (Cantidad: #{quantity})"
  end
end
