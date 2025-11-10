class OfferMailer < ApplicationMailer
  def example_email(user)
    @user = user
    mail(to: @user.email, subject: "Ejemplo de correo")
  end
end
