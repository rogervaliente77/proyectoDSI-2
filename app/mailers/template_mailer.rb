class TemplateMailer < ApplicationMailer
  def send_broadcast(template, client)
    @template = template
    @content = template.render_body_for(client)
    @theme = template.theme

    # Cargar la configuración actual del sitio
    site_config = SiteConfiguration.first
    from_email = site_config&.email_sender.presence || 'no-reply@tuempresa.com'

    # Opciones dinámicas de SMTP si hay app_password_sender configurado
    delivery_options = {}
    if site_config&.email_sender.present? && site_config&.app_password_sender.present?
      delivery_options = {
        address:              'smtp.gmail.com',
        port:                 587,
        user_name:            site_config.email_sender,
        password:             site_config.app_password_sender,
        authentication:       'plain',
        enable_starttls_auto: true
      }
    end

    mail(
      to: client.email,
      from: from_email,
      subject: template.subject,
      delivery_method_options: delivery_options
    )
  end
end