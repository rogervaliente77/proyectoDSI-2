class UserVerificationMailer < ApplicationMailer
    default from: ENV['SENDER_EMAIL']

    def send_otp_email(user)
        @user = user
        @otp_code = @user.otp_code
        mail(
        to: @user.email,
        subject: "Verificación de cuenta - Código OTP"
        )
    end
    # Correo para notificaciones habilitadas
    def allow_notifications_email(user)
        @user = user
        mail(to: @user.email, subject: "Notificaciones habilitadas")
    end
end
