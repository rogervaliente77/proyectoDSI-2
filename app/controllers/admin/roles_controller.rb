module Admin
  class RolesController < ApplicationController
    before_action :set_current_user
    before_action :set_role, only: [:edit, :update, :destroy]
    layout 'dashboard'

    # Listado de roles
    def index
      @roles = Role.all
      # Solo super_admin puede ver todos
      unless @current_user.role == "super_admin"
        redirect_to admin_home_path
        return
      end
    end

    # Formulario para nuevo rol
    def new
      @role = Role.new
    end

    # Crear rol
    def create
      @role = Role.new(role_params)
      if @role.save
        redirect_to admin_roles_path, notice: "Rol creado con éxito."
      else
        flash[:alert] = "Hubo un error al crear el rol"
        render :new, status: :unprocessable_entity
      end
    end

    # Formulario para editar rol
    def edit
    end

    # Actualizar rol
    def update
      if @role.update(role_params)
        redirect_to admin_roles_path, notice: "Rol actualizado correctamente."
      else
        flash[:alert] = "Error al actualizar el rol."
        render :edit
      end
    end

    # Eliminar rol
    def destroy
      @role.destroy
      redirect_to admin_roles_path, notice: "Rol eliminado correctamente."
    end

    private

    def set_current_user
      @current_user = current_user
    end

    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(:name, :description)
    end
  end
end
