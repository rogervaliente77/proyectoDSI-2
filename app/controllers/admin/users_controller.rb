module Admin
  class UsersController < ApplicationController
    before_action :check_admin_access
    before_action :set_current_user
    layout 'dashboard'
    def index
      @users = User.all
    end

    #Esta función sirve para actualizar los roles desde el administrador
     def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "Rol actualizado correctamente."
      else
        redirect_to admin_users_path, alert: "Error al actualizar el rol."
      end
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

     def user_params
    params.require(:user).permit(:is_admin)
    end
  end

end
