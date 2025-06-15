class Product < ApplicationRecord
  
  has_many :product_sales
  belongs_to :category

  validates :name, :price, :quantity, presence: true
end