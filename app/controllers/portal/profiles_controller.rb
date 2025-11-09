module Portal
  class ProfilesController < Portal::ApplicationController
    before_action :require_login
    before_action :set_user
    layout "dashboard"

    def show
      # Crea una dirección vacía si el usuario aún no tiene
      @user.addresses.build if @user.addresses.blank?
    end

    def update
      # Guardar imagen de perfil (antes del redirect)
      if params[:user][:profile_image].present?
        uploaded_file = params[:user][:profile_image]

        # ✅ Sube el archivo a Cloudinary
        result = Cloudinary::Uploader.upload(uploaded_file.path, folder: "users/profile_images")

        # ✅ Guarda la URL segura
        @user.profile_image_url = result["secure_url"]
      end


      if @user.update(user_params)
        redirect_to portal_profile_path, notice: "Perfil actualizado correctamente."
      else
        flash.now[:alert] = "Error al actualizar el perfil."
        render :show, status: :unprocessable_entity
      end
    end

    def destroy
      address = @current_user.addresses.find_by(params[:id])

       if address
        address.destroy
        render json: { success: true, message: "Dirección eliminada correctamente." }
      else
        render json: { success: false, message: "No se encontró la dirección." }, status: :not_found
      end
    rescue => e
      render json: { success: false, message: "Error al eliminar: #{e.message}" }, status: :internal_server_error
    
    end

    private

    def set_user
      @user = @current_user
      redirect_to portal_login_path, alert: "Debes iniciar sesión." unless @user
    end

    def user_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :phone_number,
        :profile_image,
        addresses_attributes: [
          :id,
          :name,
          :department,
          :municipality,
          :street,
          :house,
          :reference,
          :_destroy
        ]
      )
    end
  end
end

