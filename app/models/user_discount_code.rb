# app/models/user_discount_code.rb
class UserDiscountCode
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: BSON::ObjectId
  field :discount_code_id, type: BSON::ObjectId

  index({ user_id: 1, discount_code_id: 1 }, { unique: true })
end
