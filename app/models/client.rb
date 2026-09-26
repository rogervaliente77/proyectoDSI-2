class Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre, type: String
  field :telefono, type: String
  field :email, type: String
  field :is_active, type: Boolean, default: true

  # --- Campos para DTE (Hacienda) ---
  field :tipo_documento_id, type: String # "13" = DUI, "36" = NIT, "03" = Pasaporte, "37" = Otro
  field :num_documento, type: String     # Número de DUI o NIT sin guiones
  field :nrc, type: String               # Registro fiscal (obligatorio en Crédito Fiscal)
  field :nombre_comercial, type: String  # Nombre de la empresa / negocio
  field :cod_actividad, type: String     # Código de Giro/Actividad económica de Hacienda
  field :desc_actividad, type: String    # Descripción del Giro
  field :direccion, type: String         # Dirección complementaria
  field :departamento, type: String      # Código Hacienda (ej: "02" Santa Ana)
  field :municipio, type: String         # Código Hacienda (ej: "03" Chalchuapa)

  has_many :client_cars, dependent: :destroy
end