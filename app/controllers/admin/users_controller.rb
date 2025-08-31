module Admin
  class UsersController < ApplicationController
    #before_action :check_admin_access
    before_action :set_current_user
    layout 'dashboard'
    def index
      
      @users = User.all
      unless @current_user.role == "super_admin"
        redirect_to admin_home_path
        return
      end
    end

    def new

    end

    #Función para crear usuario desde el super_admin
    def create
      @user = User.new(user_params)
    
      if @user.save
        redirect_to admin_users_path, notice: "Usuario creado con éxito."
      else
        flash[:alert] = "Hubo un error al crear el usuario"
        render :new, status: :unprocessable_entity
      end
    end

    #Esta función sirve para actualizar los roles desde el administrador  
    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])

      #binding.pry
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "Usuario actualizado correctamente."
      else
        redirect_to admin_users_path, alert: "Error al actualizar el usuario."
      end
    end

    def edit_password
      @user = User.find(params[:id])
    end

    def show

    end

    def update_password
      @user = User.find(params[:id])

      if @user.update(user_params_password)
          flash[:notice] = "Clave actualizada exitosamente"
          redirect_to admin_users_edit_password_path(id: @user.id)
        else
          flash.now[:alert] = @user.errors.full_messages.join(", ")
          render :edit_password
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
      params.require(:user).permit(:is_valid, :first_name, :last_name, :role, :password, :password_confirmation, :email)
    end

    def user_params_password
      params.require(:user).permit(:password, :password_confirmation)
    end

    def created_user_params
      params.require(:user).permit(:is_valid, :first_name, :last_name, :role, :password, :password_confirmation, :email)
    end
  end

end
