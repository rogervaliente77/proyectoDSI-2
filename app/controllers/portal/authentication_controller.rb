module Portal
  class AuthenticationController < ApplicationController
    before_action :set_config
    before_action :check_checkout_intent, only: [:login, :signup, :new_login, :user_request]
    skip_before_action :authenticate_user!, only: [:login, :signup, :validating_user, :user_request, :signup_create, :new_login, :logout]
    layout 'portal_auth_layout'

    def login
      # Lógica para el formulario de login
    end

    def new_login
      #binding.pry
      if params[:user].blank?
        redirect_to admin_login_path, alert: "No ingresó datos, ingrese los datos en el formulario", status: :see_other
        return
      end
    
      email = params[:user][:email].presence
      password = params[:user][:password].presence
    
      if email.blank? || password.blank?
        redirect_to admin_login_path, alert: "Debe ingresar correo y contraseña", status: :see_other
        return
      end
    
      @user = User.where(email: email).first
    
      if @user.nil?
        redirect_to portal_login_path(checkout_params), alert: "Usuario no existe", status: :see_other
        return
      end
    
      unless @user.role&.name == "cliente"
        redirect_to admin_login_path, alert: "Usted no es usuario cliente, debe iniciar sesión en el login para administradores", status: :see_other
        return
      end
    
      unless @user.is_valid?
        @user.update(otp_code: generate_otp_code)
        session[:jwt_token] = @user.jwt_token
        UserVerificationMailer.send_otp_email(@user).deliver_now
        redirect_to portal_validating_user_path(checkout_params), alert: "Usuario no validado, debe ingresar el código de verificación que se envió a su correo", status: :see_other
        return
      end
    
      if @user.authenticate(password)
        session_token = SecureRandom.hex(32)
        session_expiration_time = Time.now + 30.minutes
    
        user_session = UserSession.create!(
          session_token: session_token,
          expiration_time: session_expiration_time,
          user_id: @user.id,
          user_email: @user.email
        )
    
        session[:user_id] = @user.id
        session[:session_token] = user_session.session_token

        # Redirige a portal_home_path con ?checkout=true si venía del modal de pago
        redirect_url = portal_home_path(checkout_params)
        clear_checkout_intent # Limpiamos la bandera en la sesión
    
        redirect_to redirect_url, notice: "¡Bienvenido, #{@user.first_name}!", status: :see_other
      else
        redirect_to portal_login_path(checkout_params), alert: "Contraseña incorrecta", status: :see_other
      end
    end
    
    def signup
      @user = User.new
    end

    def user_request
      @user = User.new(user_params_for_user)
      
      @user.otp_code = generate_otp_code
      @user.jwt_token = SecureRandom.hex(20)
      @user.role = Role.where(name: 'cliente').first
      @user.enabled = false

      if @user.save
        session[:jwt_token] = @user.jwt_token
        session[:pending_client_data] = {
          nombre: @user.full_name,
          email: @user.email,
          phone_number: @user.phone_number,
          direccion: params.dig(:user, :direccion),
          departamento: params.dig(:user, :departamento),
          municipio: params.dig(:user, :municipio)
        }

        UserVerificationMailer.send_otp_email(@user).deliver_now
        redirect_to portal_validating_user_path(checkout_params), notice: "Solicitud recibida con éxito"
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :signup, status: :unprocessable_entity
      end
    end

    def validating_user
      @jwt_token = session[:jwt_token]
    end

    def signup_create
      user = User.find_by(jwt_token: params[:user][:jwt_token])
      
      if user && user.otp_code == params[:user][:otp_code].to_i
        user.update(enabled: true)

        client_data = session[:pending_client_data] || {}
        Client.find_or_create_by(email: user.email) do |client|
          client.nombre       = user.full_name
          client.telefono     = client_data["phone_number"] || user.phone_number
          client.direccion    = client_data["direccion"]
          client.departamento = client_data["departamento"]
          client.municipio    = client_data["municipio"]
          client.is_active    = true
        end

        session.delete(:pending_client_data)

        session_token = SecureRandom.hex(32)
        session_expiration_time = Time.now + 30.minutes

        user_session = UserSession.create!(
          session_token: session_token,
          expiration_time: session_expiration_time,
          user_id: user.id,
          user_email: user.email
        )

        user.update(session_token_id: user_session.id)

        session[:user_id] = user.id.to_s
        session[:session_token] = session_token

        # Redirige a portal_home_path con ?checkout=true si correspondía
        redirect_url = portal_home_path(checkout_params)
        clear_checkout_intent

        redirect_to redirect_url, notice: "Cuenta creada y verificada exitosamente"
      else
        redirect_to portal_validating_user_path(checkout_params), alert: "Código OTP inválido. Revisa tu correo."
      end
    end

    def logout
      user_session = UserSession.find_by(session_token: session[:session_token])
      
      if user_session
        user_session.update(expiration_time: Time.current)
      end
      
      reset_session
      redirect_to portal_login_path, notice: "Sesión cerrada exitosamente"
    end
    
    private

    # 1. Guarda en la sesión si el usuario viene del flujo de pago
    def check_checkout_intent
      if params[:checkout].to_s == 'true' || params.dig(:user, :checkout).to_s == 'true'
        session[:checkout] = true
      end
    end

    # 2. Helper para armar los parámetros de redirección de forma limpia
    def checkout_params
      session[:checkout] ? { checkout: true } : {}
    end

    # 3. Elimina la bandera de sesión tras una autenticación exitosa
    def clear_checkout_intent
      session.delete(:checkout)
    end

    def set_user
      @user = User.find(params[:id])
    end

    def user_params_for_user
      params.require(:user).permit(
        :first_name, :last_name, :email, :password, 
        :password_confirmation, :phone_number
      )
    end
    
    def client_extra_params
      params.require(:user).permit(:direccion, :departamento, :municipio)
    end

    def generate_otp_code
      rand(100000..999999)
    end

    def generate_unique_jwt_token
      loop do
        token = SecureRandom.hex(16)
        break token unless User.where(jwt_token: token).exists?
      end
    end

    def set_config
      @config = SiteConfiguration.first || SiteConfiguration.new
    end
  end
end