class Devolucion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :client_id, type: BSON::ObjectId
  field :client_name, type: String
  field :sale_id, type: BSON::ObjectId
  field :sale_devolucion_detalle, type: Array, default: []  # [{ product_id: ..., cantidad: ..., precio_unitario: ... }]

  field :fecha_devolucion, type: DateTime
  field :comments_devolucion, type: String
  field :total_a_devolver, type: Float, default: 0.0
  #Nuevo PD1-42
  field :is_authorized, type: Boolean, default: false

  belongs_to :caja, class_name: "Caja", inverse_of: :sales
  belongs_to :cajero, class_name: "Cajero", inverse_of: :sales
  belongs_to :sale

  # Calcular total según los productos y cantidades seleccionadas
  def calcular_total
    total = 0
    sale_devolucion_detalle.each do |item|
      total += item['precio_unitario'].to_f * item['cantidad'].to_i
    end
    self.total_a_devolver = total
  end

  # Relaciones
  belongs_to :caja, class_name: "Caja", inverse_of: :devoluciones, optional: true
  belongs_to :cajero, class_name: "Cajero", inverse_of: :devoluciones, optional: true
  belongs_to :sale, class_name: "Sale", inverse_of: :devoluciones

  # Si tuvieras modelo Client
  # belongs_to :client, class_name: "Client", optional: true
end
