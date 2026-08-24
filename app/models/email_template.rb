# app/models/email_template.rb
class EmailTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject, type: String
  field :body_html, type: String

  belongs_to :email_theme, optional: true
  belongs_to :customer_list, optional: true

  # Alias para poder usar `theme` si lo prefieres
  alias_method :theme, :email_theme
  alias_method :theme=, :email_theme=

  validates :name, :subject, :body_html, :email_theme_id, presence: true

  def render_body_for(client)
    body_html.gsub('{{nombre_cliente}}', client.name.to_s)
             .gsub('{{email_cliente}}', client.email.to_s)
  end
end