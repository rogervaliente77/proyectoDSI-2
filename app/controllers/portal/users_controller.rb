module Portal
  class UsersController < ApplicationController
    #before_action :check_admin_access
    # before_action :set_current_user
    before_action :set_config
    layout 'portal_landing'
    # def index

    def update
      @user = User.find(params[:id])
    
      if @user.update(user_params)
        redirect_to portal_users_edit_password_path(id: @user.id), notice: "Contraseña actualizada correctamente."
      else
        # Capturamos los errores del modelo o enviamos el mensaje genérico
        error_msg = @user.errors.full_messages.to_sentence.presence || "Error al actualizar la contraseña."
        redirect_to portal_users_edit_password_path(id: @user.id), alert: error_msg
      end
    end

    def edit_password
      @user = User.find(params[:id])
    end

    private

    def user_params
      params.require(:user).permit(:is_valid, :first_name, :last_name, :role, :password, :password_confirmation, :email)
    end

    def created_user_params
      params.require(:user).permit(:is_valid, :first_name, :last_name, :role, :password, :password_confirmation, :email)
    end

    def set_config
      # Ajusta según cómo obtienes las configuraciones globales (ej. Config.first, SystemSetting.first, etc.)
      @config = SiteConfiguration.first || SiteConfiguration.new
    end
  end

end
