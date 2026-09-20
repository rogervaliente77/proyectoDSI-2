# app/models/product_history.rb
class ProductHistory
  include Mongoid::Document
  include Mongoid::Timestamps

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
  field :movement_type, type: String  # "Creación de servicio", "Ingreso de stock", "Ajuste de tarifa", etc.
  field :user_id,       type: BSON::ObjectId

  belongs_to :product, validate: false
  belongs_to :user, optional: true

  # Métodos auxiliares para la vista de historial
  def service_history?
    stock_before.nil? && current_stock.nil?
  end

  def formatted_movement
    return "#{movement_type}" if service_history?

    "#{movement_type} (Stock: #{stock_before || 0} → #{current_stock || 0})"
  end
end