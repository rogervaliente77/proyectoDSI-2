module Admin
  class CategoriesController < ApplicationController
    before_action :set_category, only: [:edit, :update, :destroy]
    layout 'dashboard'
    # GET /admin/categories
    def index
      @categories = Category.all
    end

    # GET /admin/categories/new
    def new
      @category = Category.new
    end

    # POST /admin/categories
    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "Categoría creada correctamente."
      else
        flash.now[:alert] = "Hubo un error al crear la categoría."
        render :new
      end
    end

    # GET /admin/categories/:id/edit
    def edit
        @category = Category.find(params[:id])
    end


    # PATCH/PUT /admin/categories/:id
    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Categoría actualizada correctamente."
      else
        flash.now[:alert] = "Hubo un error al actualizar la categoría."
        render :edit
      end
    end

    # DELETE /admin/categories/:id
    def destroy
      @category.destroy
      redirect_to admin_categories_path, notice: "Categoría eliminada correctamente."
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :description)
    end
  end
end
