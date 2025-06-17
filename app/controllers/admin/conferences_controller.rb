module Admin
  class ConferencesController < ApplicationController
    before_action :check_admin_access
    before_action :set_current_user
    layout 'dashboard'
    
    def index
      @users = User.all
      @charlas = Conference.all
    end

    def new
      @conference = Conference.new
    end

    def create
        @conference = Conference.new(conference_params)
      
        if @conference.save
          redirect_to admin_charlas_path, notice: "Conferencia creada con éxito."
        else
          flash[:alert] = "Hubo un error al crear la conferencia."
          render :new, status: :unprocessable_entity
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

    def conference_params
      params.require(:conference).permit(:title, :speaker_name, :description, :start_date, :end_date, :max_limit_of_attendees, :image_url)
    end
  end
end
