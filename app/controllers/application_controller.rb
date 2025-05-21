class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # before_action :check_admin_access

  private

  def authenticate_user!
    # Verifica si hay una sesión activa
    if session[:user_id].present? && session[:session_token].present?
      user_session = UserSession.find_by(session_token: session[:session_token])

      # binding.pry
      # Si el token no existe o ha expirado, cerrar sesión
      if user_session.nil? || user_session.expiration_time < Time.current
        reset_session  # Limpia los datos de la sesión en Rails
        redirect_to portal_login_path, alert: "Sesión expirada, por favor inicia sesión nuevamente"
        # render json: { error: 'Sesión expirada, por favor inicia sesión nuevamente' }, status: :unauthorized
      else
        @current_user = User.find(session[:user_id]) # Guarda el usuario autenticado
      end
    else
      redirect_to portal_login_path, alert: "Registrate o Inicia Sesión"
      # render json: { error: 'Acceso no autorizado' }, status: :unauthorized
    end
  end

  # def check_admin_access
  #   # Recupera el correo de usuario admin desde el archivo .env
  #   binding.pry
  #   # Compara el correo del usuario logueado con el correo de administrador
  #   if @current_user.email != ENV['USER_ADMIN']
  #     redirect_to portal_home_path, alert: "No tienes acceso a esta sección"
  #   end
  # end

  def current_user
    @current_user
  end

end
