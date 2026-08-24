# app/controllers/admin/email_templates_controller.rb
module Admin
  class EmailTemplatesController < ApplicationController
    before_action :set_template, only: [:show, :edit, :update, :destroy, :send_to_active_clients]
    layout 'dashboard'

    def index
      @templates = EmailTemplate.all.order_by(created_at: :desc)
    end

    def show; end

    def new
      @template = EmailTemplate.new

      # Buscar el tema seleccionado o tomar el primero disponible por defecto
      theme = EmailTheme.find_by(id: params[:theme_id]) rescue nil
      theme ||= EmailTheme.first

      if theme
        @template.email_theme = theme
        # Si tienes métodos en EmailTheme para valores por defecto:
        @template.subject = theme.try(:default_subject)
        @template.body_html = theme.try(:default_body)
      end
    end

    def create
      @template = EmailTemplate.new(template_params)
      if @template.save
        redirect_to admin_email_templates_path, notice: "Plantilla creada correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @template.update(template_params)
        redirect_to admin_email_templates_path, notice: "Plantilla actualizada correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to admin_email_templates_path, notice: "Plantilla eliminada."
    end

    # Acción para masivo de correos
    def send_to_active_clients
      # Asumiendo modelo Client con campo active: true
      active_clients = Client.where(active: true) 

      active_clients.each do |client|
        TemplateMailer.send_broadcast(@template, client).deliver_later
      end

      redirect_to admin_email_template_path(@template), notice: "Envío masivo iniciado para #{active_clients.count} clientes activos."
    end

    def send_broadcast
      @template = EmailTemplate.find(params[:id])
      customer_list = @template.customer_list

      unless customer_list
        redirect_to admin_email_template_path(@template), alert: "La plantilla no tiene una lista de clientes asignada."
        return
      end

      clients = customer_list.clients

      if clients.empty?
        redirect_to admin_email_template_path(@template), alert: "La lista '#{customer_list.name}' no contiene clientes."
        return
      end

      # Enviar a cada cliente de la lista
      clients.each do |client|
        TemplateMailer.send_broadcast(@template, client).deliver_later
      end

      redirect_to admin_email_template_path(@template), notice: "Correo en cola de envío para #{clients.count} clientes de la lista '#{customer_list.name}'."
    end

    private

    def set_template
      @template = EmailTemplate.find(params[:id])
    end

    def template_params
      params.require(:email_template).permit(:name, :subject, :body_html, :slug, :email_theme_id, :customer_list_id)
    end
  end
end