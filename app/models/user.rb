class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword

  # Campos
  field :first_name,       type: String
  field :last_name,        type: String
  field :full_name,        type: String
  field :jwt_token,        type: String
  field :email,            type: String
  field :phone_number,     type: String
  field :password_digest,  type: String
  field :is_valid,         type: Mongoid::Boolean, default: true
  field :session_token_id, type: String
  field :otp_code,         type: Integer
  field :is_admin,         type: Mongoid::Boolean, default: false
  # field :role,             type: String, default: "cliente"
  field :allow_notifications, type: Mongoid::Boolean, default: false # NUEVO CAMPO

  # Relacionamientos (ajústalos a tus modelos Mongoid)
  has_many :user_sessions, class_name: "UserSession", inverse_of: :user
  belongs_to :role

  # Seguridad de contraseña
  has_secure_password

  # Validaciones
  validates :first_name, :last_name, presence: { message: "Nombres y apellidos requeridos" }
  validates :email, presence: { message: "Correo electrónico requerido" }, uniqueness: { message: "Este correo ya está en uso" }
  validates :jwt_token, uniqueness: { message: "Este token ya está en uso" }, allow_blank: true
  validates :password, presence: true, length: { minimum: 3 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?

  # Callbacks
  before_save :save_full_name

  # Métodos
  def save_full_name
    self.full_name = "#{first_name} #{last_name}".strip
  end

  def password_required?
    new_record? || !password.nil?
  end
end
