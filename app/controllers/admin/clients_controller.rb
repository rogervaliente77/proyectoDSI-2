module Admin
  class ClientsController < Admin::ApplicationController
    before_action :set_current_user
    # before_action :check_admin_access
    # before_action :set_product, only: %i[ product_sales edit update destroy]
    layout 'dashboard'
    
    def index
      # binding.pry
      @clients = Client.all
    end

    def new
      @client = Client.new

      if params[:tipo_cliente] == "natural"
        @tipo_cliente = "natural"
      else
        @tipo_cliente = "juridico"
      end
    end

    def create
      @client = Client.new(client_params)

      if @client.tipo_cliente == "natural"
        # --- Validaciones ---
        if params[:client][:first_name].blank?
          flash[:alert] = "El nombre es obligatorio."
          return redirect_to new_admin_client_path(tipo_cliente: "natural")
        end

        if params[:client][:last_name].blank?
          flash[:alert] = "El apellido es obligatorio."
          return redirect_to new_admin_client_path(tipo_cliente: "natural")
        end

        # --- Construir full_name ---
        @client.full_name = "#{params[:client][:first_name]} #{params[:client][:last_name]}"

        # --- Generar código CN-xxxx ---
        @client.code = next_codigo("CN")

      else # JURÍDICO
        # --- Validaciones ---
        if params[:client][:full_name].blank?
          flash[:alert] = "El nombre de la empresa es obligatorio."
          return redirect_to new_admin_client_path(tipo_cliente: "juridico")
        end

        if params[:client][:nit].blank?
          flash[:alert] = "El NIT es obligatorio."
          return redirect_to new_admin_client_path(tipo_cliente: "juridico")
        end

        # --- Generar código CJ-xxxx ---
        @client.code = next_codigo("CJ")
      end

      # Guardar
      if @client.save
        flash[:notice] = "Cliente creado correctamente."
        redirect_to admin_clients_path
      else
        flash[:alert] = @client.errors.full_messages.join(", ")
        render :new
      end
    end

    def edit
      @caja = Caja.find(params[:id])
    end

    # def product_sales
    #   @products = @product&.product_sales
    # end

    # def edit
    #   # binding.pry
    # end

    def update
      @caja = Caja.find(params[:id])

      respond_to do |format|
        if @caja.update(caja_params)
          format.html {redirect_to admin_cajas_path, notice: "Caja actualizada con éxito" }
        else
          format.html { redirect_to admin_cajas_path, alert: "Ocurrio un error" }
        end
      end
    end

    # def mark_as_delivered
    #   @product_sale = ProductSale.find(params[:product_sale_id])
    
    #   if @product_sale.update(was_delivered: !@product_sale.was_delivered, delivered_at: Time.now)
    #     redirect_to admin_product_sales_path(product_id: @product_sale.product.id), notice: "Producto actualizado con éxito.", status: :see_other
    #   else
    #     redirect_to admin_product_sales_path(product_id: @product_sale.product.id), alert: "Hubo un problema al actualizar el producto", status: :see_other
    #   end
    # end
    
    # def destroy
    #   # binding.pry
    #   @product.destroy!
  
    #   respond_to do |format|
    #     format.html { redirect_to admin_productos_path, status: :see_other, notice: "Producto eliminado exitosamente" }
    #     format.json { head :no_content }
    #   end
    # end

    private

    # def check_admin_access
    #   if current_user.is_admin == false
    #     redirect_to portal_home_path, alert: "No tienes acceso a esta sección"
    #   end
    # end

    # def set_product
    #   @product = Product.find(params[:product_id]) || nil
    # end

    def set_current_user
      @current_user = current_user
    end

    def client_params
      params.require(:client).permit(:first_name, :last_name, :full_name, :email, :phone_number, :address,
                                   :giro, :nit, :dui, :tipo_cliente)
    end

    def next_codigo(prefijo)
      # Busca el último documento cuyo codigo empiece por "CN-" o "CJ-"
      regex = /^#{Regexp.escape(prefijo)}-/
      ultimo = Client.where(code: regex).order_by(code: :desc).limit(1).pluck(:code).first

      if ultimo.present?
        numero = ultimo.split("-").last.to_i + 1
      else
        numero = 1
      end

      numero_formateado = numero.to_s.rjust(7, "0")
      "#{prefijo}-#{numero_formateado}"
    end

  end
end
