class Empleado
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos
  field :first_name, type: String
  field :last_name, type: String
  field :full_name, type: String
  field :email, type: String
  field :phone_number, type: String
  field :address, type: String
  field :cargo_name, type: String
  field :cargo_id, type: BSON::ObjectId
  field :nit, type: String
  field :dui, type: String
  field :fecha_inicio_trabajo, type: DateTime
  field :fecha_nacimiento, type: DateTime
  field :status, type: String
  field :banco_medio_pago, type: String
  field :cuenta_bancaria, type: String
  field :nivel_educacion, type: String
  field :salario, type: Float, default: 0.00
  field :otros_ingresos1, type: Float, default: 0.00
  field :otros_ingresos2, type: Float, default: 0.00
  field :otros_ingresos3, type: Float, default: 0.00
  field :detalle_otros_ingresos1, type: String
  field :detalle_otros_ingresos1, type: String 
  field :detalle_otros_ingresos1, type: String

end