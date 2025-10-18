class ReturnedProduct
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :quantity, type: Integer
  field :unit_price, type: Float
  field :discount, type: Float
  field :returned_at, type: DateTime

  belongs_to :sale
  belongs_to :product
  belongs_to :devolucion

end
