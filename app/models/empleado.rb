class Empleado
  include Mongoid::Document
  include Mongoid::Timestamps

  # Informacion Personal
  field :first_name, type: String
  field :last_name, type: String
  field :full_name, type: String
  field :email, type: String
  field :phone_number, type: String
  field :address, type: String
  field :nit, type: String
  field :dui, type: String
  field :fecha_nacimiento, type: DateTime
  field :status, type: String
  field :hire_date, type: DateTime
  field :fecha_inicio_trabajo, type: DateTime
  field :edad, type: Integer
  field :nivel_educacion, type: String

  #Informacion Laboral
  field :employee_code, type: String
  field :cargo_name, type: String
  field :cargo_id, type: BSON::ObjectId
  field :departament_job_name, type: String
  field :department_job_id, type: BSON::ObjectId
  field :salary, type: Float, default: 0.00
  field :salary_type, type: String #mensual, quincenal, por hora
  field :contract_type, type: String #indefinido, temporal, por obra
  field :work_shift, type: String #diurno, nocturno, mixto
  field :boss_id, type: BSON::ObjectId
  field :entry_hour, type: String
  field :departure_hour, type: String

  #Informacion bancaria
  field :banco_medio_pago, type: String
  field :cuenta_bancaria, type: String
  field :pension_system, type: String
  field :insurance_number, type: String

end