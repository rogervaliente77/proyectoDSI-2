# app/models/returned_product.rb
class ReturnedProduct
  include Mongoid::Document
  include Mongoid::Timestamps

  field :quantity, type: Integer
  field :unit_price, type: Float
  field :discount, type: Float
  field :condicion, type: String, default: "buen_estado" # "buen_estado" o "defectuoso"
  field :returned_at, type: DateTime

  belongs_to :product
  belongs_to :sale
  belongs_to :devolucion
end