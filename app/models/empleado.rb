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

  field :status, type: String, default: 'Activo'
  field :banco_medio_pago, type: String
  field :cuenta_bancaria, type: String
  field :cargo_name, type: String
  field :nivel_educacion, type: String
  field :salario_quincenal, type: Float, default: 0.00
  field :salario_mensual, type: Float, default: 0.00
  field :otros_ingresos1, type: Float, default: 0.00
  field :otros_ingresos2, type: Float, default: 0.00
  field :otros_ingresos3, type: Float, default: 0.00
  field :detalle_otros_ingresos1, type: String
  field :detalle_otros_ingresos1, type: String 
  field :detalle_otros_ingresos1, type: String
  field :grado_academico, type: String
  field :nivel_educacion, type: String
  field :porcentaje_pago_actual, type: Float, default: 1.0
  field :fecha_inicio_trabajo, type: Date
  # Si es nil, hereda de ConfiguracionPlanilla. Si no, se define un array ej: [1,2,3,4,5]
  field :dias_laborales_personalizados, type: Array, default: nil

  has_many :asistencias
  has_many :boletas_de_pago, class_name: "BoletaDePago"

  # Campos que no pueden estar vacíos
  validates :first_name, :last_name, :dui, :cargo_name, presence: { message: "es obligatorio" }
  
  # El correo debe tener formato válido y ser único
  validates :email, 
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no tiene un formato válido" },
            allow_blank: true # Permite que esté vacío si no lo tienes a la mano
  
  # DUI único para evitar registros duplicados (Clave en El Salvador)
  validates :dui, uniqueness: { message: "ya está registrado en el sistema" }
  
  # Validar que el salario sea un número positivo
  validates :salario_mensual, numericality: { greater_than_or_equal_to: 0, message: "debe ser un monto válido" }

  validates :dui, format: { with: /\A\d{8}-\d\z/, message: "debe tener el formato 00000000-0" }

  # --- CALLBACKS ---
  before_save :generate_full_name
  before_save :calculate_quincena

  # Helper para saber qué días trabaja este empleado específico
  def dias_laborales
    dias_laborales_personalizados.present? ? dias_laborales_personalizados : ConfiguracionPlanilla.actual.dias_laborales_defecto
  end

  private

  def generate_full_name
    self.full_name = "#{first_name} #{last_name}"
  end

  def calculate_quincena
    self.salario_quincenal = (salario_mensual || 0) / 2
  end
end
