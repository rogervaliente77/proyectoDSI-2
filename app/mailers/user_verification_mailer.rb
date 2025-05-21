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
end
