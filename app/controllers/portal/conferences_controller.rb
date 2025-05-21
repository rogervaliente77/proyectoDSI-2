module Portal
  class ConferencesController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :set_current_user

    def index
      # binding.pry
      # Lógica para el formulario de login
      conference_ids = @current_user.conference_registrations.pluck(:conference_id)
      @not_related_conferences = Conference.not_in(id: conference_ids)
    end

    def my_registrations
      # binding.pry
      @my_charlas = @current_user.conference_registrations
    end

    private

    def set_current_user
      @current_user = current_user
    end
  end
end