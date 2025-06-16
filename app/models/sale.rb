class Sale < ApplicationRecord
  belongs_to :caja
  belongs_to :cajero
  has_many :product_sales, inverse_of: :sale, dependent: :destroy
  accepts_nested_attributes_for :product_sales, allow_destroy: true
end
