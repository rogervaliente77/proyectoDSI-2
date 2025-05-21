module Admin
  class UsersController < ApplicationController
    before_action :check_admin_access
    before_action :set_current_user
    layout 'dashboard'
    def index
      @users = User.all
    end

    private

    def check_admin_access
      admin_email = ENV['USER_ADMIN']

      unless current_user && current_user.email == admin_email
        redirect_to portal_home_path, alert: "No tienes acceso a esta sección."
      end
    end

    def set_current_user
      @current_user = current_user
    end
  end
end
