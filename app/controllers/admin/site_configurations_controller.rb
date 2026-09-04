class Admin::SiteConfigurationsController < Admin::ApplicationController
  layout 'dashboard'
  before_action :set_config

  def show
  end

  def update
    if @config.update(config_params)
      redirect_to admin_site_configuration_path, notice: "Configuración actualizada correctamente."
    else
      flash.now[:alert] = "Error al actualizar la configuración."
      render :show, status: :unprocessable_entity
    end
  end

  def upload_slide
    if params[:slide_image].present?
      uploaded = Cloudinary::Uploader.upload(params[:slide_image], folder: "site_slider")
      next_position = @config.header_slides.count
      
      @config.header_slides.create!(
        image_url: uploaded['secure_url'],
        public_id: uploaded['public_id'],
        position: next_position,
        badge_text: params[:badge_text],
        title_part1: params[:title_part1],
        title_part2: params[:title_part2],
        description: params[:description]
      )
      redirect_to admin_site_configuration_path, notice: "Lámina agregada exitosamente al slider."
    else
      redirect_to admin_site_configuration_path, alert: "Por favor selecciona una imagen válida."
    end
  end

  def destroy_slide
    slide = @config.header_slides.find(params[:slide_id])
    if slide.destroy
      redirect_to admin_site_configuration_path, notice: "Lámina eliminada correctamente."
    else
      redirect_to admin_site_configuration_path, alert: "No se pudo eliminar la lámina."
    end
  end

  def reorder_slides
    positions = params[:positions]
    if positions.present?
      positions.each_with_index do |id, index|
        @config.header_slides.find(id).update(position: index)
      end
      render json: { status: 'success' }, status: :ok
    else
      render json: { status: 'error' }, status: :bad_request
    end
  end

  private

  def set_config
    @config = SiteConfiguration.first_or_create
  end

  def config_params
    params.require(:site_configuration).permit(
      :session_timeout, :currency_symbol, :timezone, :email_sender,
      :app_password_sender, :company_name, :company_email, :tel, :phone,
      :address, :short_address, :wsp_number, :fb_url, :inst_url, :tiktok_url,
      :etiqueta_superior, :header_title_part1, :header_title_part2,
      :header_description, :services_title, :services_description,
      :categories_title, :categories_description, :footer_company_description,
      :footer_services,
      header_slides_attributes: [
        :id, :image_url, :public_id, :position, :_destroy,
        :badge_text, :title_part1, :title_part2, :description
      ]
    )
  end
end