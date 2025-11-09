module Portal
  class ApplicationController < ::ApplicationController
    before_action :authenticate_user!
    # before_action :check_admin_access

    private

    def authenticate_user!
      if session[:user_id].present? && session[:session_token].present?
        user_session = UserSession.find_by(session_token: session[:session_token])
        @current_user = User.find_by(id: session[:user_id])

        if user_session.nil? || user_session.expiration_time < Time.current
          reset_session
          redirect_to portal_login_path, alert: "Sesión expirada, por favor inicia sesión nuevamente"
        end
      else
        redirect_to portal_login_path, alert: "Registrate o Inicia Sesión"
      end
    end

    def check_admin_access
      return if @current_user.nil?
      return if @current_user.email == ENV['USER_ADMIN']
      redirect_to portal_home_path, alert: "No tienes acceso a esta sección"
    end

    def current_user
      @current_user
    end

     def require_login
      unless @current_user
        redirect_to portal_login_path, alert: "Debes iniciar sesión para acceder a esta sección."
      end
    end
  end
end