module Admin
  class CustomerListsController < ApplicationController
    layout 'dashboard'
    before_action :set_customer_list, only: [:show, :edit, :update, :destroy]

    def index
      @customer_lists = CustomerList.all
    end

    def show
    end

    def new
      @customer_list = CustomerList.new
    end

    def create
      @customer_list = CustomerList.new(customer_list_params_without_clients)
      assign_clients_data

      if @customer_list.save
        redirect_to admin_customer_lists_path, notice: "Lista de clientes creada correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @customer_list.assign_attributes(customer_list_params_without_clients)
      assign_clients_data

      if @customer_list.save
        redirect_to admin_customer_lists_path, notice: "Lista de clientes actualizada correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @customer_list.destroy
      redirect_to admin_customer_lists_path, notice: "Lista eliminada correctamente.", status: :see_other
    end

    private

    def set_customer_list
      @customer_list = CustomerList.find(params[:id])
    end

    def customer_list_params_without_clients
      params.require(:customer_list).permit(:name, :description)
    end

    # Extrae los clientes seleccionados y construye el arreglo de objetos [{ id: ..., email: ..., name: ... }]
    def assign_clients_data
      selected_ids = params.dig(:customer_list, :selected_client_ids)&.reject(&:blank?) || []

      if selected_ids.any?
        clients = Client.where(:id.in => selected_ids)
        @customer_list.clients_data = clients.map do |client|
          # Ajusta los campos según tu modelo Client
          client_name = client.try(:nombre) || "Sin nombre"

          {
            "id" => client.id.to_s,
            "email" => client.email,
            "name" => client_name
          }
        end
      else
        @customer_list.clients_data = []
      end
    end
  end
end