# app/controllers/admin/product_histories_controller.rb
module Admin
  class ProductHistoriesController < ApplicationController
    layout 'dashboard'
    before_action :set_product_history, only: [:show]

    def index
      @product_histories = ProductHistory.all.order_by(created_at: :desc)
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
