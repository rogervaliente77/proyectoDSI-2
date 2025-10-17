# app/controllers/admin/product_histories_controller.rb
module Admin
  class ProductHistoriesController < ApplicationController
    layout 'dashboard'
    before_action :set_product_history, only: [:show]

    def index
      @product_histories = ProductHistory.all

      # 🔹 Filtro por rango de fechas
      if params[:start_date].present? && params[:end_date].present?
        start_date = DateTime.parse(params[:start_date]).beginning_of_day
        end_date   = DateTime.parse(params[:end_date]).end_of_day
        @product_histories = @product_histories.where(:created_at.gte => start_date, :created_at.lte => end_date)
      end

      # 🔹 Filtro por nombre parcial de usuario
      if params[:user_name].present?
        name_query = Regexp.new(Regexp.escape(params[:user_name]), Regexp::IGNORECASE)
        # Obtener los IDs de usuarios que coincidan
        matching_user_ids = User.or({ first_name: name_query }, { last_name: name_query }).pluck(:id)
        @product_histories = @product_histories.where(:user_id.in => matching_user_ids)
      end

      # 🔹 Ordenar por fecha descendente
      @product_histories = @product_histories.order_by(created_at: :desc)

      render "admin/products/histories_index"
    end

    def show
      render "admin/products/histories_show"
    end

    private

    def set_product_history
      @product_history = ProductHistory.find(params[:id])
      redirect_to admin_product_histories_path, alert: "Historial no encontrado" unless @product_history
    end
  end
end
