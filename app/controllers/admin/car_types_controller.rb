module Admin
    class CarTypesController < ApplicationController
      before_action :set_car_type, only: [:edit, :update, :destroy]
      layout 'dashboard'
  
      def index
        @car_types = CarType.all.asc(:name)
      end
  
      def new
        @car_type = CarType.new
      end
  
      def create
        @car_type = CarType.new(car_type_params)
        if @car_type.save
          redirect_to admin_car_types_path, notice: "Tipo de vehículo creado exitosamente."
        else
          flash.now[:alert] = "Hubo un error al crear el tipo de vehículo."
          render :new, status: :unprocessable_entity
        end
      end
  
      def edit
      end
  
      def update
        if @car_type.update(car_type_params)
          redirect_to admin_car_types_path, notice: "Tipo de vehículo actualizado exitosamente."
        else
          flash.now[:alert] = "Hubo un error al actualizar el tipo de vehículo."
          render :edit, status: :unprocessable_entity
        end
      end
  
      def destroy
        @car_type.destroy
        redirect_to admin_car_types_path, notice: "Tipo de vehículo eliminado correctamente."
      end
  
      private
  
      def set_car_type
        @car_type = CarType.find(params[:id])
      end
  
      def car_type_params
        params.require(:car_type).permit(:name, :description)
      end
    end
  end