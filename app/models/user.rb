class User
  include Mongoid::Document
  include Mongoid::Timestamps
  # include ActiveModel::SecurePassword

  field :first_name, type: String
  field :last_name, type: String
  field :full_name, type: String
  field :jwt_token, type: String
  field :email, type: String
  field :phone_number, type: String
  field :password, type: String
  field :password_confirmation, type: String
  field :is_valid, type: Boolean, default: false
  field :session_token_id, type: BSON::ObjectId
  field :otp_code, type: Integer
  field :is_admin, type: Boolean, default: false

  belongs_to :user_session, optional: true, inverse_of: :user
  has_many :conference_registrations
  has_many :conferences

  # has_secure_password

  validates :first_name, :last_name, presence: { message: "Nombres y apellidos requeridos" }
  validates :email, presence: { message: "Correo electrónico requerido" }, uniqueness: { message: "Este correo ya está en uso" }
  # validates :password, presence: { message: "Contraseña requerida" }, confirmation: { message: "La confirmación de la contraseña no coincide" }
  validates :jwt_token, uniqueness: { message: "Este token ya esta en uso" }
  validates :password, presence: true, length: { minimum: 3 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?

  before_create :save_full_name

  def save_full_name
    self.full_name = "#{self.first_name} #{self.last_name}"
  end

  def password_required?
    new_record? || password.present?
  end
end
