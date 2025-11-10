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
      render :show, alert: "Error al actualizar configuración."
    end
  end

  def mass_mail
    if @config.mass_mail_enabled?
      clients = Client.where(receive_offers: true)
      clients.each do |client|
        OfferMailer.mass_offer_email(client).deliver_later
      end
      redirect_to admin_site_configuration_path, notice: "Correos enviados a #{clients.count} clientes."
    else
      redirect_to admin_site_configuration_path, alert: "El envío masivo está deshabilitado."
    end
  end

  private

  def set_config
    @config = SiteConfiguration.first_or_create!
  end

  def config_params
    params.require(:site_configuration).permit(:session_timeout, :offer_notifications_enabled, :mass_mail_enabled)
  end

  def not
  @config = SiteConfiguration.first_or_create!
  end


end
