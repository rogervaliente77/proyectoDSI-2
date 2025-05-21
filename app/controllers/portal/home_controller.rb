module Portal
  class HomeController < ApplicationController
    layout 'dashboard'
    # before_action :authenticate_user!

    def index
      # binding.pry
      # Lógica para el formulario de login
      @current_user = current_user
    end
  end
end