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
        filename = "#{SecureRandom.hex}_#{uploaded_file.original_filename}"
        filepath = Rails.root.join('public', 'uploads', filename)

        FileUtils.mkdir_p(File.dirname(filepath))
        File.open(filepath, 'wb') { |f| f.write(uploaded_file.read) }

        @user.profile_image = filename
      end

      if @user.update(user_params)
        redirect_to portal_profile_path, notice: "Perfil actualizado correctamente."
      else
        flash.now[:alert] = "Error al actualizar el perfil."
        render :show, status: :unprocessable_entity
      end
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

