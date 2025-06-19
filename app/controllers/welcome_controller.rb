
  class WelcomeController < ApplicationController
    layout 'dashboard'
    # before_action :authenticate_user!

    def index
      # binding.pry
      # Lógica para el formulario de login
      # @current_user = current_user
      @products = Product.all
    end
  end
