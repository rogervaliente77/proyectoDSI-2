module Admin
  class AuthenticationController < Admin::ApplicationController
    #skip_before_action :authenticate_user!, only: [:login, :signup, :validating_user, :user_request, :signup_create, :new_login, :logout]
    skip_before_action :authenticate_user!, only: [
      :login, :signup, :validating_user, :user_request, :signup_create, :new_login, :logout
    ]

    # skip_before_action :check_admin_access, only: [
    # :login, :signup, :validating_user, :user_request, :signup_create, :new_login, :logout
    #] 

    def login
      # Lógica para el formulario de login
      # binding.pry
    end

    def new_login
      # binding.pry
      if params[:user].blank?
        redirect_to admin_login_path, alert: "No ingresó datos, ingrese los datos en el formulario"
        return
      end
    
      email = params[:user][:email].presence
      password = params[:user][:password].presence
    
      if email.blank? || password.blank?
        redirect_to admin_login_path, alert: "Debe ingresar correo y contraseña"
        return
      end
    
      begin
        @user = User.find_by(email: email)
      rescue Mongoid::Errors::DocumentNotFound
        @user = nil
      end

      if !@user.present?
        redirect_to admin_login_path, alert: "Usuario no existe"
        return
      end

      if @user.role.name == "cliente"
        flash[:alert] = 'Usted no es administrador, debe ingresar en este login de clientes'
        redirect_to portal_login_path
        return
      end

      if @user.present?
        if !@user.is_valid?
          respond_to do |format|
            @user.update(otp_code: generate_otp_code)
            session[:jwt_token] = @user.jwt_token
            @user = User.find(@user.id)
            UserVerificationMailer.send_otp_email(@user).deliver_now
            flash[:alert] = 'Usuario no validado, debe ingresar el codigo de verificacion que se envio a su correo'
            redirect_to admin_validating_user_path
            return
          end
        end
      else
        flash[:alert] = 'Usuario con ese correo no esta registrado'
        redirect_to admin_login_path
        return
      end
    
      # Validamos que el usuario exista y que la contraseña sea correcta
      if @user&.authenticate(password)
        session_token = SecureRandom.hex(32)
        session_expiration_time = Time.now + 30.minutes # o el tiempo que necesites
        # binding.pry
        # Crea un UserSession
        user_session = UserSession.create!(
          session_token: session_token,
          expiration_time: session_expiration_time,
          user_id: @user.id,
          user_email: @user.email
        )
    
        session[:user_id] = @user.id
        session[:session_token] = user_session.session_token
        flash[:notice] = "Bienvenido, #{@user.first_name}!"
        redirect_to admin_home_path
        return
      else
        redirect_to admin_login_path, alert: "Contraseña incorrecta"
      end
    end
    
    def signup

    end

    def user_request
      # binding.pry
      @user = User.new(user_params)
      @user.otp_code = generate_otp_code # Genera un código aleatorio de 6 dígitos
      @user.jwt_token = SecureRandom.hex(20)
  
      if @user.save
        # Si el registro es exitoso
        session[:jwt_token] = @user.jwt_token
        UserVerificationMailer.send_otp_email(@user).deliver_later
        redirect_to portal_validating_user_path, notice: "Solicitud recibida con exito"
      else
        # Si hay errores, renderiza el formulario nuevamente
        flash[:alert] = @user.errors.full_messages.to_sentence
        render :signup
      end
    end

    def validating_user
      # binding.pry
      # unless session[:jwt_token]
      #   redirect_to portal_login_path, alert: "Sesión inválida. Registrate o Inicia Sesion" and return
      # end
    
      @jwt_token = session[:jwt_token]
    end

    def signup_create
      # binding.pry
      # Lógica para validar y crear el usuario
      # Encuentra al usuario por jwt_token y valida su otp_code
      user = User.where(jwt_token: params[:user][:jwt_token]).first
      if user && user.otp_code.to_i == params[:user][:otp_code].to_i
        user.update(is_valid: true)

        # Crea un nuevo token de sesión
        session_token = SecureRandom.hex(32)
        session_expiration_time = Time.now + 30.minutes  # o el tiempo que necesites

        # Crea un UserSession
        user_session = UserSession.create!(
          session_token: session_token,
          expiration_time: session_expiration_time,
          user_id: user.id,
          user_email: user.email
        )

        # Asocia el session_token_id con el usuario
        user.update(session_token_id: user_session.id)

        # Almacena la sesión en Rails
        session[:user_id] = user.id.to_s # MongoDB usa ObjectId, convertirlo a string es buena práctica
        session[:session_token] = session_token

        # Devuelve la respuesta o redirige
        redirect_to admin_home_path, notice: "Autenticacion con exito"   
        #render json: { message: 'Usuario validado', session_token: session_token }
      else
        redirect_to admin_validating_user_path, alert: "Otp code invalido, por favor ingrese el codigo enviado a su corrreo"
        #render json: { error: 'Código OTP incorrecto' }, status: :unauthorized
      end
    end

    def logout
      #binding.pry  # Para inspeccionar el flujo
    
      # Busca la sesión usando el token guardado en las cookies de sesión
      user_session = UserSession.find_by(session_token: session[:session_token])
      
      # Si la sesión existe, actualizamos su tiempo de expiración
      if user_session
        user_session.update(expiration_time: Time.current)
      end
      
      # Borra los datos de la sesión
      reset_session
      
      # Redirige al login
      redirect_to admin_login_path, notice: "Sesión cerrada exitosamente"
    end
    
    # vr20033@ues.edu.sv
    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end

    def generate_otp_code
      rand(100000..999999) # Genera un número aleatorio entre 100000 y 999999
    end

    def generate_unique_jwt_token
      loop do
        token = SecureRandom.hex(16) # Genera un token de 32 caracteres (16 bytes en hexadecimal)
        break token unless User.where(jwt_token: token).exists?
      end
    end
  end
end
