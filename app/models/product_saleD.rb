class ProductSaleD < ApplicationRecord
  # belongs_to :sale
  # belongs_to :product

  # before_create :update_product_stock

  # def update_product_stock
  #   product = self.product

  #   product.quantity = product.quantity - self.quantity

  #   product.save
  # end
end
