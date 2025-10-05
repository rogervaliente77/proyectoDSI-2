 # app/models/devolucion.rb
class Devolucion
  include Mongoid::Document
  include Mongoid::Timestamps # Para created_at y updated_at automáticos

  field :client_id, type: BSON::ObjectId
  field :client_name, type: String
  field :sale, type: Array, default: []
  field :fecha_devolucion, type: DateTime
  field :comments_devolucion, type: String

  belongs_to :caja, class_name: "Caja", inverse_of: :sales
  belongs_to :cajero, class_name: "Cajero", inverse_of: :sales
  belongs_to :sale
end
