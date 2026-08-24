# app/models/email_theme.rb
class EmailTheme
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :primary_color, type: String, default: '#2c3e50'
  field :background_color, type: String, default: '#f4f6f9'
  field :card_bg_color, type: String, default: '#ffffff'
  field :text_color, type: String, default: '#333333'
  field :header_html, type: String
  field :footer_html, type: String

  has_many :email_templates

  validates :name, :primary_color, :background_color, presence: true

  # Configuración para la previsualización interactiva con JavaScript
  def to_json_config
    {
      id: id.to_s,
      primary_color: primary_color,
      background_color: background_color,
      card_bg_color: card_bg_color,
      text_color: text_color,
      header_html: header_html.to_s,
      footer_html: footer_html.to_s
    }.to_json
  end
end