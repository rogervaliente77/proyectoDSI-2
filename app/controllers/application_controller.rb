class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_admin_access

  private

  def authenticate_user!
    # Verifica si hay una sesión activa
    if session[:user_id].present? && session[:session_token].present?
      user_session = UserSession.where(session_token: session[:session_token]).first
      @current_user = User.where(id: session[:user_id]).first

      # binding.pry
      # Si el token no existe o ha expirado, cerrar sesión
      if user_session.nil? || user_session.expiration_time < Time.current
        reset_session  # Limpia los datos de la sesión en Rails
        redirect_to portal_login_path, alert: "Sesión expirada, por favor inicia sesión nuevamente"
        # render json: { error: 'Sesión expirada, por favor inicia sesión nuevamente' }, status: :unauthorized
      else
        @current_user = User.where(id: session[:user_id]).first # Guarda el usuario autenticado
      end
    else
      redirect_to portal_login_path, alert: "Registrate o Inicia Sesión"
      # render json: { error: 'Acceso no autorizado' }, status: :unauthorized
    end
  end

  def check_admin_access
    return if @current_user.nil? # No hacer nada si no hay usuario
    return if @current_user.email == ENV['USER_ADMIN'] # Es admin
  
    redirect_to portal_home_path, alert: "No tienes acceso a esta sección"
  end  

  def current_user
    @current_user
  end

end
