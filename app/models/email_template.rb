class EmailTemplate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject, type: String
  field :body_html, type: String

  belongs_to :email_theme, optional: true
  belongs_to :customer_list, optional: true

  alias_method :theme, :email_theme
  alias_method :theme=, :email_theme=

  validates :name, :subject, :body_html, :email_theme_id, presence: true

  def render_body_for(client, extra_context = {})
    render_text(body_html, client, extra_context)
  end

  def render_subject_for(client, extra_context = {})
    render_text(subject, client, extra_context)
  end

  # --- NUEVOS MÉTODOS PARA RENDERIZAR HEADER Y FOOTER DINÁMICOS ---
  def render_header_for(client, extra_context = {})
    return '' if email_theme&.header_html.blank?
    render_text(email_theme.header_html, client, extra_context)
  end

  def render_footer_for(client, extra_context = {})
    return '' if email_theme&.footer_html.blank?
    render_text(email_theme.footer_html, client, extra_context)
  end

  private

  def render_text(text_content, client, extra_context = {})
    return '' if text_content.blank?

    placeholders = build_global_placeholders(client, extra_context)

    # Reemplaza cualquier {{etiqueta}} o {{prefijo.campo}}
    text_content.gsub(/\{\{\s*([\w\.]+)\s*\}\}/) do |match|
      var_name = $1
      placeholders.key?(var_name) ? placeholders[var_name].to_s : match
    end
  end

  def build_global_placeholders(client, extra_context = {})
    vars = {}

    # 1. Fecha y Hora del Sistema
    now = Time.current
    vars['fecha']    = I18n.l(now.to_date, format: :long) rescue now.strftime('%d/%m/%Y')
    vars['hora']     = now.strftime('%I:%M %p')
    vars['hora_24h'] = now.strftime('%H:%M')
    vars['anio']     = now.year.to_s

    # 2. Cargar Mapeos Globales desde SiteConfiguration en BD
    site_config = SiteConfiguration.first
    if site_config.present?
      if site_config.custom_variables.is_a?(Hash)
        site_config.custom_variables.each do |k, v|
          vars[k.to_s.gsub(/[\{\}]/, '')] = v
        end
      end

      if site_config.global_mappings.is_a?(Hash)
        site_config.global_mappings.each do |prefix, config|
          next if config.blank?
          obj = fetch_object_from_config(config, client)
          extract_attributes_into(vars, obj, prefix: prefix.to_s) if obj.present?
        end
      end
    end

    # 3. Contexto extra (si envías compras, productos, etc.)
    extra_context.each do |prefix, object|
      next if object.nil?
      extract_attributes_into(vars, object, prefix: prefix.to_s)
    end

    vars
  end

  def fetch_object_from_config(config, context_client = nil)
    return nil unless config.is_a?(Hash)

    find_strategy = config['find_by'].to_s

    if find_strategy == 'context' || find_strategy == 'client'
      return context_client
    end

    model_class = config['model'].to_s.safe_constantize
    return nil unless model_class

    case find_strategy
    when 'first'
      model_class.first
    when 'find', 'id'
      model_class.where(_id: config['value']).first
    when 'where'
      field_name = config['field'] || '_id'
      model_class.where(field_name => config['value']).first
    else
      model_class.first
    end
  rescue StandardError => e
    Rails.logger.error "Error resolviendo mapeo global: #{e.message}"
    nil
  end

  def extract_attributes_into(hash_target, object, prefix: nil)
    attrs = object.respond_to?(:attributes) ? object.attributes : (object.is_a?(Hash) ? object : {})

    attrs.each do |key, val|
      next if key.to_s.in?(%w[_id created_at updated_at encrypted_password])

      full_key = prefix.present? ? "#{prefix}.#{key}" : key.to_s
      hash_target[full_key] = val
      hash_target["#{prefix}_#{key}"] = val if prefix.present?
    end
  end
end