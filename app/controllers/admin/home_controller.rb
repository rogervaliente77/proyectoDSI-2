module Admin
  class HomeController < Admin::ApplicationController
    layout 'dashboard'

    def index
      # Ya tiene acceso a @current_user, @pending_devoluciones_count y @low_stock_products
    end
  end
end
