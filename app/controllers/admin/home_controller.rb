module Admin
  class HomeController < Admin::ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :check_pending_devoluciones

    def index
      # binding.pry
      # Lógica para el formulario de login
      @current_user = current_user
    end
    #PD1-42
    def check_pending_devoluciones
      if current_user && current_user.role && ["admin", "super_admin"].include?(current_user.role.name)
        @pending_devoluciones_count = Devolucion.where(is_authorized: false).count
      else
        @pending_devoluciones_count = 0
      end
    end
    
  end
end