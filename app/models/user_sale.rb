# app/models/user_sale.rb
class UserSale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sale_date, type: DateTime

  # Relaciones
  belongs_to :sale
  belongs_to :user

  # Índices (equivalentes a los que tenías en SQL)
  index({ sale_id: 1 })
  index({ user_id: 1 })
end
