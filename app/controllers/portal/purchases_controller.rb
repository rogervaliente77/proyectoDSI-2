class Portal::PurchasesController < ApplicationController
  before_action :set_current_user
  before_action :set_header_variables  # <-- Esto es nuevo
  layout "dashboard"

  def index
    # Traer todas las compras del usuario
    @purchases = Sale.where(client_id: @current_user.id).order(sold_at: :desc)
  end

  def schedule_appointment
    @sale = Sale.find(params[:purchase_id])
    @client = User.find(@sale.client_id)
  end

  def confirm_appointment
    @sale = Sale.find(params[:delivery][:sale_id])
    @client = User.find(@sale.client_id)

    # binding.pry
    @delivery = Delivery.new(delivery_params)
    @delivery.client_id = @client.id
    @delivery.client_name = @client.full_name
    @delivery.sale_code = @sale.code
    @delivery.has_appointment = true

    # binding.pry
    if @delivery.save
      flash[:success] = "Cita agendada correctamente"
      redirect_to portal_purchase_estado_entrega_path(@sale)
    else
      flash[:error] = "Hubo un error al agendar la cita: #{@delivery.errors.full_messages.join(', ')}"
      redirect_to portal_purchase_schedule_appointment_path(@sale)
    end
    
  end

  def delivery_status_real_time
    @sale = Sale.find(params[:purchase_id])
  end

  def update_delivery_status
     
  end

  def refresh_delivery_status
    @sale = Sale.find(params[:purchase_id])
    render partial: "portal/purchases/delivery_status_real_time", locals: { sale: @sale }
  end  

  private

  # Mantener current_user
  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def delivery_params
    params.require(:delivery).permit(:appointment_date, :appointment_hour, :delivery_address, :sale_id)
  end

  # ----------------- NUEVO -----------------
  # Variables necesarias para el headerbar
  def set_header_variables
    if @current_user&.role&.name == 'cliente'
      @offer_products = Product.all.select(&:on_offer?)
    else
      @offer_products = []
    end
  end
end
