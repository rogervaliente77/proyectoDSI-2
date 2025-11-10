module Admin
  class ApplicationController < ::ApplicationController
    before_action :authenticate_user!
    before_action :check_pending_devoluciones
    before_action :load_low_stock_products
    before_action :load_client_notifications # 👈 Notificaciones visibles para el cliente también

    private

    # ------------------- Autenticación -------------------
    def authenticate_user!
      if session[:user_id].present? && session[:session_token].present?
        user_session = UserSession.find_by(session_token: session[:session_token])
        @current_user = User.find_by(id: session[:user_id])

        if user_session.nil? || user_session.expiration_time < Time.current
          reset_session
          redirect_to admin_login_path, alert: "Sesión expirada, por favor inicia sesión nuevamente"
        end
      else
        redirect_to admin_login_path, alert: "Regístrate o inicia sesión"
      end
    end

    # ------------------- Acceso de administrador -------------------
    def check_admin_access
      return if @current_user.nil?
      return if @current_user.email == ENV['USER_ADMIN']
      redirect_to admin_home_path, alert: "No tienes acceso a esta sección"
    end

    def current_user
      @current_user
    end

    # ------------------- Notificaciones globales -------------------

    # Cantidad de devoluciones pendientes (solo admin/super_admin)
    def check_pending_devoluciones
      if @current_user&.role&.name.in?(%w[admin super_admin])
        @pending_devoluciones_count = Devolucion.where(is_authorized: false).count
      else
        @pending_devoluciones_count = 0
      end
    end

    # Productos con bajo stock (solo administradores)
    def load_low_stock_products
      @low_stock_products = Product.where(:quantity.lte => 25)
      # Si usaras ActiveRecord:
      # @low_stock_products = Product.where("quantity <= ?", 25)
    end

    # 🔔 Notificaciones visibles para clientes también
    def load_client_notifications
      if @current_user.present?
        case @current_user.role&.name
        when 'cliente'
          # Notificaciones para el cliente (ej. ofertas y descuentos)
          @client_notifications = Product.where(:offer_type.ne => nil)
                                         .or(:discount.gt => 0)
                                         .limit(10)
        when 'admin', 'super_admin'
          # Los administradores no necesitan duplicar notificaciones
          @client_notifications = []
        else
          @client_notifications = []
        end
      else
        @client_notifications = []
      end
    end
  end
end
