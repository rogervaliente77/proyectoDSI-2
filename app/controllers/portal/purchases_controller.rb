class Portal::PurchasesController < ApplicationController
  before_action :set_current_user
  before_action :set_config
  before_action :set_header_variables  # <-- Esto es nuevo
  layout "portal_landing"

  def index
    @client = Client.find(current_user.client_id)
    if @current_user.client.present?
      @sales = Sale.where(client_id: @current_user.client.id).order_by(sold_at: :desc)
    else
      @sales = []
    end
  end

  # def schedule_appointment
  #   @sale = Sale.find(params[:purchase_id])
  #   @client = User.find(@sale.client_id)
  # end

  # def confirm_appointment
  #   @sale = Sale.find(params[:delivery][:sale_id])
  #   @client = User.find(@sale.client_id)

  #   # binding.pry
  #   @delivery = Delivery.new(delivery_params)
  #   @delivery.client_id = @client.id
  #   @delivery.client_name = @client.full_name
  #   @delivery.sale_code = @sale.code
  #   @delivery.has_appointment = true

  #   # binding.pry
  #   if @delivery.save
  #     flash[:success] = "Cita agendada correctamente"
  #     redirect_to portal_purchase_estado_entrega_path(@sale)
  #   else
  #     flash[:error] = "Hubo un error al agendar la cita: #{@delivery.errors.full_messages.join(', ')}"
  #     redirect_to portal_purchase_schedule_appointment_path(@sale)
  #   end
    
  # end

  # def delivery_status_real_time
  #   @sale = Sale.find(params[:purchase_id])
  # end

  # def update_delivery_status
     
  # end

  # def refresh_delivery_status
  #   @sale = Sale.find(params[:purchase_id])
  #   render partial: "portal/purchases/delivery_status_real_time", locals: { sale: @sale }
  # end

  def upload_proof
    sale = Sale.find(params[:purchase_id])
    uploaded_file = params[:transfer_proof] # Viene del input type="file"

    if uploaded_file.present?
      # 1. Definir el directorio de destino en el servidor (ej. public/uploads/comprobantes)
      upload_dir = Rails.root.join('public', 'uploads', 'comprobantes')
      FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)

      # 2. Generar un nombre único para evitar colisiones
      file_extension = File.extname(uploaded_file.original_filename)
      unique_filename = "comprobante_#{sale.code}_#{SecureRandom.hex(4)}#{file_extension}"
      file_path = upload_dir.join(unique_filename)

      # 3. Escribir el archivo físicamente en el disco del servidor Ubuntu
      File.open(file_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end

      # 4. Guardar la ruta relativa en la base de datos y actualizar estatus
      relative_path = "/uploads/comprobantes/#{unique_filename}"
      sale.update(
        transfer_proof_path: relative_path,
        status: 'pending_check_payment_comprob'
      )

      sale.update_status_with_log(
        'pending_check_payment_comprob', 
        current_user.id, 
        "Comprobante de transferencia subido y almacenado en el servidor."
      )

      @sale = Sale.find(sale.id)

      ActionCable.server.broadcast("admin_online_sales", { 
        action: "update_status", 
        sale_id: @sale.id.to_s, 
        code: @sale.code,
        client_name: @sale.client_name,
        status: @sale.status,
        forma_pago: @sale.forma_pago,
        delivery_method: @sale.delivery_method
      })

      redirect_to portal_purchases_path, notice: "Comprobante subido exitosamente. En proceso de revisión."
    else
      redirect_to portal_purchases_path, alert: "Por favor selecciona un archivo válido."
    end
  end

  def download_ticket
    @sale = Sale.find(params[:id])
    pdf_data = SaleTicketPdf.new(@sale).render
    
    send_data pdf_data,
              filename: "ticket_#{@sale.code}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  rescue Mongoid::Errors::DocumentNotFound
    redirect_to portal_purchases_path, alert: "Pedido no encontrado."
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

  def set_config
    # Ajusta según cómo obtienes las configuraciones globales (ej. Config.first, SystemSetting.first, etc.)
    @config = SiteConfiguration.first || SiteConfiguration.new
  end
end
