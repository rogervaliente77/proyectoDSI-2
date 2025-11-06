class Delivery
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :sale_code, type: String
  field :delivery_code, type: String
  field :client_name, type: String
  field :client_id, type: BSON::ObjectId
  field :package_status, type: String, default: "in_warehouse" #picked_up
  field :delivery_status, type: String, default: "unassigned"  #assigned, picked_up, in_route, onsite, delivered, rejected, returned_to_warehouse
  field :appointment_date, type: DateTime
  field :has_appointment, type: Boolean, default: false
  field :status_log_changes, type: Array, default: []
  field :sale_id, type: BSON::ObjectId

  belongs_to :sale
  belongs_to :delivery_driver

  # Validaciones
  validates :sale_code, :delivery_code, presence: { message: "El codigo de venta y delivery son obligatorios" }, uniqueness: { message: "Codigo de venta o delivery ya existe" }

end
