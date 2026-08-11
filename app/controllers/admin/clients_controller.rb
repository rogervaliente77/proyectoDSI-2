module Admin  
  class ClientsController < Admin::ApplicationController
    before_action :set_client, only: [:show, :edit, :update, :destroy]
    layout 'dashboard'

    def index
      @clients = Client.all.order(created_at: :desc)
    end

    def show
      @client_cars = @client.client_cars
    end

    def new
      @client = Client.new
    end

    def create
      @client = Client.new(client_params)
      if @client.save
        redirect_to admin_client_path(@client), notice: 'Cliente creado exitosamente.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @client.update(client_params)
        redirect_to admin_client_path(@client), notice: 'Cliente actualizado correctamente.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @client.destroy
      redirect_to admin_clients_path, notice: 'Cliente eliminado.'
    end

    private

    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.require(:client).permit(:nombre, :telefono, :email, :is_active)
    end
  end
end