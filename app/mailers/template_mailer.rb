class TemplateMailer < ApplicationMailer
  layout 'template_mailer'

  def send_broadcast(template, client)
    @template = template
    @theme    = template.theme

    # Se parsean las variables en todas las partes del contenido
    @header_content = template.render_header_for(client)
    @content        = template.render_body_for(client)
    @footer_content = template.render_footer_for(client)

    # Renderizar asunto dinámico
    subject_rendered = template.render_subject_for(client)

    site_config = SiteConfiguration.first
    from_email = site_config&.email_sender.presence || 'no-reply@tuempresa.com'

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
      subject: subject_rendered,
      delivery_method_options: delivery_options
    )
  end
end