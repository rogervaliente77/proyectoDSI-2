# app/models/site_configuration.rb
class SiteConfiguration
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :header_slides, cascade_callbacks: true
  accepts_nested_attributes_for :header_slides, allow_destroy: true

  field :session_timeout, type: Integer, default: 60 # minutos
  #field :offer_notifications_enabled, type: Boolean, default: true
  #field :mass_mail_enabled, type: Boolean, default: false

  field :currency_symbol, type: String, default: "$"
  field :timezone, type: String, default: "America/El_Salvador"
  #field :maintenance_mode, type: Boolean, default: false
  #field :debug_mode, type: Boolean, default: false

  field :email_sender, type: String
  field :app_password_sender, type: String

  field :company_name, type: String
  field :tel, type: String
  field :phone, type: String
  field :address, type: String
  field :short_address, type: String
  field :company_email, type: String

  #Social media
  field :wsp_number, type: String
  field :fb_url, type: String
  field :inst_url, type: String
  field :tiktok_url, type: String

  #section header
  field :etiqueta_superior, type: String
  field :header_title_part1, type: String
  field :header_title_part2, type: String
  field :header_description, type: String

  #Section Servicios
  field :services_title, type: String
  field :services_description, type: String

  #Section Categories
  field :categories_title, type: String
  field :categories_description, type: String

  #footer
  field :footer_company_description, type: String
  field :footer_services, type: String

  # Mapeos globales cargados para TODAS las plantillas
  # Ej: { "sucursal" => { "model" => "Branch", "find_by" => "first" },
  #       "promocion" => { "model" => "Promotion", "find_by" => "where", "field" => "active", "value" => true } }
  field :global_mappings, type: Hash, default: {}

  # Variables globales estáticas (Clave -> Valor)
  # Ej: { "telefono_soporte" => "2222-0000", "horario" => "8 AM - 5 PM" }
  field :custom_variables, type: Hash, default: {}

  def self.current_session_timeout
    (first&.session_timeout || 60).minutes
  end
end