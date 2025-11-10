module Portal
  class AddressesController < ApplicationController
    before_action :set_address, only: [:destroy]

    def destroy
      if @address.destroy
        render json: { success: true, message: 'Dirección eliminada correctamente.' }
      else
        render json: { success: false, message: 'No se pudo eliminar la dirección.' }, status: :unprocessable_entity
      end
    end

     def show
    address = current_user.addresses.find(params[:id])
    render json: { success: true, address: address }
  rescue
    render json: { success: false, message: "Dirección no encontrada" }, status: :not_found
  end

  
  def update
     @address = Address.find(params[:id])

  if @address.update(address_params)
    respond_to do |format|
      format.json { render json: { success: true, message: "Dirección actualizada correctamente." }, status: :ok }
      format.html { redirect_to portal_profile_path, notice: "Dirección actualizada correctamente." }
    end
  else
    respond_to do |format|
      format.json { render json: { success: false, message: @address.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      format.html { redirect_to portal_profile_path, alert: "Error al actualizar dirección." }
    end
  end
    
  end


 
    private

    def set_address
      @address = Address.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: 'Dirección no encontrada.' }, status: :not_found
    end
    
    def address_params
        params.require(:address).permit(:name, :department, :municipality, :street, :house, :reference)
    end
  end
  

end
