# app/controllers/admin/email_themes_controller.rb
module Admin
  class EmailThemesController < ApplicationController
    before_action :set_theme, only: [:show, :edit, :update, :destroy]
    layout 'dashboard'

    def index
      @themes = EmailTheme.all.order_by(created_at: :desc)
    end

    def show; end

    def new
      @theme = EmailTheme.new(
        primary_color: '#0d6efd',
        background_color: '#f8f9fa',
        card_bg_color: '#ffffff',
        text_color: '#212529',
        header_html: '<h2 style="margin: 0; text-align: center;">FerrePro</h2>',
        footer_html: '<p style="text-align: center; font-size: 12px; color: #6c757d;">© 2026 FerrePro. Todos los derechos reservados.</p>'
      )
    end

    def create
      @theme = EmailTheme.new(theme_params)
      if @theme.save
        redirect_to admin_email_themes_path, notice: "Tema creado correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @theme.update(theme_params)
        redirect_to admin_email_themes_path, notice: "Tema actualizado correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @theme.destroy
      redirect_to admin_email_themes_path, notice: "Tema eliminado."
    end

    private

    def set_theme
      @theme = EmailTheme.find(params[:id])
    end

    def theme_params
      params.require(:email_theme).permit(
        :name, :primary_color, :background_color, 
        :card_bg_color, :text_color, :header_html, :footer_html
      )
    end
  end
end