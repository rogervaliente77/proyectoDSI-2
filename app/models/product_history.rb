# app/models/product_history.rb
class ProductHistory
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :name,          type: String
  field :description,   type: String
  field :quantity,      type: Integer
  field :price,         type: Float
  field :code,          type: String
  field :discount,      type: Integer, default: 0
  field :cash_in,       type: Float
  field :cash_out,      type: Float
  field :sale_id,       type: BSON::ObjectId
  field :devolucion_id, type: BSON::ObjectId
  field :stock_before,  type: Integer
  field :current_stock, type: Integer
  field :movement_type, type: String  # Tipo: Ingreso, Salida, Ajuste
  field :user_id,       type: BSON::ObjectId  # <-- Nuevo

  belongs_to :product
  belongs_to :user, optional: true          # Relación con el usuario
end
