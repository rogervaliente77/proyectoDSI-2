module Admin
  class HomeController < Admin::ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :check_pending_devoluciones
    before_action :load_low_stock_products  # Nuevo before_action

    def index
      @current_user = current_user
      # Ahora @low_stock_products y @pending_devoluciones_count
      # están disponibles para la vista
    end

    private

    # PD1-42
    def check_pending_devoluciones
      if current_user && current_user.role && ["admin", "super_admin"].include?(current_user.role.name)
        @pending_devoluciones_count = Devolucion.where(is_authorized: false).count
      else
        @pending_devoluciones_count = 0
      end
    end

    # Productos con bajo stock
    def load_low_stock_products
      @low_stock_products = Product.where(:quantity.lte => 25)
      # Si usaras ActiveRecord en vez de Mongoid:
      # @low_stock_products = Product.where("quantity <= ?", 25)
    end
  end
end
