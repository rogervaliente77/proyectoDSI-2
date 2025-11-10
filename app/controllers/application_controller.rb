class ApplicationController < ActionController::Base
  helper_method :current_user

  private

  def current_user
    @current_user
  end

   def check_session_timeout
    config = SiteConfiguration.first
    timeout = (config&.session_timeout || 30).minutes

    if session[:last_seen_at] && session[:last_seen_at] < timeout.ago
      reset_session
      redirect_to root_path, alert: "Tu sesión ha expirado por inactividad."
    else
      session[:last_seen_at] = Time.current
    end
  end

end
