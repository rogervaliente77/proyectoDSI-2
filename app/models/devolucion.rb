class Devolucion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id, type: BSON::ObjectId
  field :client_name, type: String
  field :sale_devolucion_detalle, type: Array, default: []  # lista de productos devueltos
  field :fecha_devolucion, type: DateTime
  field :comments_devolucion, type: String

  # Relaciones
  belongs_to :caja, class_name: "Caja", inverse_of: :devoluciones, optional: true
  belongs_to :cajero, class_name: "Cajero", inverse_of: :devoluciones, optional: true
  belongs_to :sale, class_name: "Sale", inverse_of: :devoluciones

  # Si tuvieras modelo Client
  # belongs_to :client, class_name: "Client", optional: true
end
