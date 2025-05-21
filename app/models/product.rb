class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :quantity, type: Integer
  field :price, type: Float
  field :image_url, type: String
  
  has_many :product_sales
end
