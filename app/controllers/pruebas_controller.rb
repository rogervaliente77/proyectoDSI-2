class PruebasController < ApplicationController
  before_action :set_prueba, only: %i[ show edit update destroy ]

  # GET /pruebas or /pruebas.json
  def index
    @pruebas = Prueba.all
  end

  # GET /pruebas/1 or /pruebas/1.json
  def show
  end

  # GET /pruebas/new
  def new
    @prueba = Prueba.new
  end

  # GET /pruebas/1/edit
  def edit
  end

  # POST /pruebas or /pruebas.json
  def create
    binding.pry
    @prueba = Prueba.new(prueba_params)
    binding.pry
    respond_to do |format|
      if @prueba.save
        format.html { redirect_to @prueba, notice: "Prueba was successfully created." }
        format.json { render :show, status: :created, location: @prueba }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @prueba.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pruebas/1 or /pruebas/1.json
  def update
    respond_to do |format|
      if @prueba.update(prueba_params)
        format.html { redirect_to @prueba, notice: "Prueba was successfully updated." }
        format.json { render :show, status: :ok, location: @prueba }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @prueba.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pruebas/1 or /pruebas/1.json
  def destroy
    @prueba.destroy!

    respond_to do |format|
      format.html { redirect_to pruebas_path, status: :see_other, notice: "Prueba was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prueba
      @prueba = Prueba.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def prueba_params
      params.require(:prueba).permit(:nombre, :description)
    end
end
