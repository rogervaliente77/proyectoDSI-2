class UserD < ApplicationRecord
  has_secure_password

  has_many :user_sessions
  has_many :conference_registrations
  has_many :conferences

  # Validaciones
  validates :first_name, :last_name, presence: { message: "Nombres y apellidos requeridos" }
  validates :email, presence: { message: "Correo electrónico requerido" }, uniqueness: { message: "Este correo ya está en uso" }
  validates :jwt_token, uniqueness: { message: "Este token ya está en uso" }, allow_blank: true
  validates :password, presence: true, length: { minimum: 3 }, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_required?

  before_save :save_full_name

  def save_full_name
    self.full_name = "#{first_name} #{last_name}"
  end

  def password_required?
    new_record? || !password.nil?
  end
end