class ProductSaletes
  include Mongoid::Document
  include Mongoid::Timestamps

  field :product_name, type: String
  field :user_name, type: String
  field :user_email, type: String
  field :sold_at, type: DateTime
  field :was_delivered, type: Boolean, default: false
  field :delivered_at, type: DateTime
  field :user_data, type: Hash, default: {}
  field :product_data, type: Hash, default: {}
  
  belongs_to :user
  belongs_to :product

  before_create :update_user_score
  before_create :update_product_stock

  validates :user_id, presence: true
  validates :product_id, presence: true

  def update_user_score
    user = self.user

    user.current_score = self.user.current_score - self.product.price
    d = 9
    user.save
  end

  def update_product_stock
    product = self.product
    # binding.pry
    product.quantity = product.quantity - 1
    d = 9
    product.save
  end
end
