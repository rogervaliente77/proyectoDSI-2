# app/models/site_configuration.rb
class SiteConfiguration
  include Mongoid::Document
  include Mongoid::Timestamps

  # Configuración de sesión y notificaciones
  field :session_timeout, type: Integer, default: 60 # minutos
  field :offer_notifications_enabled, type: Boolean, default: true
  field :mass_mail_enabled, type: Boolean, default: false

  # 🔹 Campos adicionales para "Configuración general"
  field :company_name, type: String, default: "Mi Empresa"
  field :currency_symbol, type: String, default: "$"
  field :timezone, type: String, default: "America/El_Salvador"
  field :maintenance_mode, type: Boolean, default: false
  field :debug_mode, type: Boolean, default: false

  field :email_sender, type: String
  field :app_password_sender, type: String

  def self.current_session_timeout
    (first&.session_timeout || 60).minutes
  end
end
