# app/controllers/admin/marcas_controller.rb
module Admin
  class MarcasController < ApplicationController
    before_action :authenticate_user! # Asegura que el usuario esté autenticado
    before_action :set_marca, only: %i[edit update destroy]
    layout 'dashboard'

    def index
      @marcas = Marca.all
    end

    def new
      @marca = Marca.new
    end

    def create
      @marca = Marca.new(marca_params)
      if @marca.save
        redirect_to admin_marcas_path, notice: "Marca creada con éxito."
      else
        flash[:alert] = @marca.errors.full_messages.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @marca.update(marca_params)
        redirect_to admin_marcas_path, notice: "Marca actualizada con éxito."
      else
        flash[:alert] = @marca.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @marca.destroy
        redirect_to admin_marcas_path, notice: "Marca eliminada exitosamente", status: :see_other
      else
        redirect_to admin_marcas_path, alert: "No se pudo eliminar la marca", status: :unprocessable_entity
      end
    end

    private

    def set_marca
      @marca = Marca.find_by(id: params[:id])
      unless @marca
        redirect_to admin_marcas_path, alert: "Marca no encontrada"
      end
    end

    def marca_params
      params.require(:marca).permit(:name, :description)
    end
  end
end
