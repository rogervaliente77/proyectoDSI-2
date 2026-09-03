# app/controllers/admin/site_configurations_controller.rb
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

  private

  def set_config
    @config = SiteConfiguration.first_or_create
  end

  def config_params
    params.require(:site_configuration).permit(
      :session_timeout,
      :currency_symbol,
      :timezone,
      :email_sender,
      :app_password_sender,
      :company_name,
      :company_email,
      :tel,
      :phone,
      :address,
      :short_address,
      :wsp_number,
      :fb_url,
      :inst_url,
      :tiktok_url,
      :etiqueta_superior,
      :header_title_part1,
      :header_title_part2,
      :header_description,
      :services_title,
      :services_description,
      :categories_title,
      :categories_description,
      :footer_company_description,
      :footer_services
    )
  end
end