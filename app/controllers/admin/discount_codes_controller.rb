# app/controllers/admin/discount_codes_controller.rb
module Admin
  class DiscountCodesController < ApplicationController
    before_action :set_current_user
    #before_action :check_admin_access
    before_action :set_discount_code, only: %i[show edit update destroy]

    layout 'dashboard'

    def index
      @discount_codes = DiscountCode.includes(:product)
      @discount_codes = @discount_codes.where(product_id: params[:product_id]) if params[:product_id].present?
    end

    def new
      @discount_code = DiscountCode.new
    end

    def create
      @discount_code = DiscountCode.new(discount_code_params)
      if @discount_code.save
        redirect_to admin_discount_codes_path, notice: "Código de descuento creado con éxito."
      else
        flash[:alert] = "Hubo un error al crear el código."
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @discount_code.update(discount_code_params)
        redirect_to admin_discount_codes_path, notice: "Código actualizado con éxito."
      else
        flash[:alert] = "Error al actualizar el código."
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @discount_code.destroy
      redirect_to admin_discount_codes_path, notice: "Código eliminado exitosamente."
    end

    private

    def set_discount_code
      @discount_code = DiscountCode.find(params[:id])
    end

    def discount_code_params
      params.require(:discount_code).permit(:value, :discount, :due_date, :product_id)
    end

    def check_admin_access
      redirect_to portal_home_path, alert: "No tienes acceso a esta sección" unless current_user.is_admin
    end

    def set_current_user
      @current_user = current_user
    end
  end
end
