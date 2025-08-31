class CategoryD < ApplicationRecord
  has_many :products, dependent: :destroy
end