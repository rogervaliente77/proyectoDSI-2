module Admin
  class ClientCarsController < Admin::ApplicationController
    before_action :set_client

    def create
      @client_car = @client.client_cars.build(client_car_params)
      if @client_car.save
        redirect_to admin_client_path(@client), notice: 'Vehículo registrado correctamente.'
      else
        redirect_to admin_client_path(@client), alert: 'Error al registrar el vehículo. Completa los campos obligatorios.'
      end
    end

    def update
      @client = Client.find(params[:client_id])
      @client_car = @client.client_cars.find(params[:id])
    
      if @client_car.update(client_car_params)
        redirect_to admin_client_path(@client), notice: "Vehículo actualizado correctamente."
      else
        redirect_to admin_client_path(@client), alert: "Error al actualizar el vehículo."
      end
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end

    def client_car_params
      params.require(:client_car).permit(:marca, :modelo, :anio, :color, :placa, :vin, :is_active)
    end
  end
end