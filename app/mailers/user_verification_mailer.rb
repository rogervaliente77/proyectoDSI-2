class UserVerificationMailer < ApplicationMailer
    def send_otp_email(user)
      @user = user
      @otp_code = @user.otp_code
  
      # Consultamos la configuración desde la base de datos
      config = SiteConfiguration.first
  
      # Validamos que existan las credenciales registradas
      if config&.email_sender.present? && config&.app_password_sender.present?
        sender_email = config.email_sender
  
        # Modificamos dinámicamente las credenciales SMTP para esta entrega puntual
        dynamic_smtp_settings = {
          address: "smtp.gmail.com",
          port: 587,
          domain: "gmail.com",
          authentication: "plain",
          enable_starttls_auto: true,
          user_name: config.email_sender,
          password: config.app_password_sender,
          open_timeout: 20,
          read_timeout: 20
        }
  
        mail(
          from: sender_email,
          to: @user.email,
          subject: "Verificación de cuenta - Código OTP",
          delivery_method_options: dynamic_smtp_settings
        )
      else
        # Respuesto / Fallback si no se han configurado los campos en SiteConfiguration
        mail(
          from: ENV['SENDER_EMAIL'],
          to: @user.email,
          subject: "Verificación de cuenta - Código OTP"
        )
      end
    end
end