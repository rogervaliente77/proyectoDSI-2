module Admin
  class ProductsController < ApplicationController
    before_action :set_current_user
    before_action :set_product, only: %i[edit update destroy product_sales]
    layout 'dashboard'

    # LISTADO DE PRODUCTOS
    def index
      @categories = Category.all
      @products = Product.includes(:category, :marca, :car_type).all.asc(:name)
    end

    # VISTA 2: Catálogo General con Cards y Filtros Mongoid
    def catalogo
      @categories = Category.all
      @marcas = Marca.all
      @car_types = CarType.all

      @products = Product.includes(:category, :marca, :car_type).all

      if params[:query].present?
        query_regex = /#{Regexp.escape(params[:query].strip)}/i
        @products = @products.any_of({ name: query_regex }, { code: query_regex })
      end

      if params[:category_id].present?
        selected_category = Category.where(id: params[:category_id]).first
        if selected_category
          category_ids = selected_category.respond_to?(:self_and_descendant_ids) ? selected_category.self_and_descendant_ids : [selected_category.id]
          @products = @products.where(:category_id.in => category_ids)
        end
      end

      if params[:marca_id].present?
        marca_id = BSON::ObjectId.legal?(params[:marca_id]) ? BSON::ObjectId.from_string(params[:marca_id]) : params[:marca_id]
        @products = @products.where(marca_id: marca_id)
      end

      if params[:car_type_id].present?
        car_type_id = BSON::ObjectId.legal?(params[:car_type_id]) ? BSON::ObjectId.from_string(params[:car_type_id]) : params[:car_type_id]
        @products = @products.where(car_type_id: car_type_id)
      end

      if params[:min_price].present? || params[:max_price].present?
        min_price = params[:min_price].present? ? params[:min_price].to_f : 0
        max_price = params[:max_price].present? ? params[:max_price].to_f : Float::INFINITY
        @products = @products.where(:price.gte => min_price, :price.lte => max_price)
      end

      if params[:offer].present? && params[:offer] != "todas"
        @products = @products.where(offer_type: params[:offer])
      end

      @products = @products.asc(:name)
    end
  
    # NUEVO PRODUCTO
    def new
      @product = Product.new
      @categories = Category.all
      @marcas = Marca.all
      @product.product_images.build
      @offers = Offer.active
    end

    # CREAR PRODUCTO
    def create
      @product = Product.new(product_params)
      @product.current_user_id = current_user&.id

      if @product.save
        redirect_to admin_productos_path, notice: "Producto creado con éxito."
      else
        flash[:alert] = "Hubo al crear el producto: #{@product.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    # EDITAR PRODUCTO
    def edit
      @categories = Category.all
      @marcas = Marca.all
      @product.product_images.build if @product.product_images.empty?
      @offers = Offer.active
    end

    # ACTUALIZAR PRODUCTO
    def update
      @product.current_user_id = current_user&.id

      if @product.update(product_params)
        redirect_to admin_edit_product_path(product_id: @product.id), notice: "#{@product.servicio? ? 'Servicio' : 'Producto'} actualizado con éxito"
      else
        flash[:alert] = @product.errors.full_messages.join(", ")
        render :edit
      end
    end

    # ELIMINAR PRODUCTO
    def destroy
      @product.destroy!
      redirect_to admin_productos_path, notice: "Producto eliminado exitosamente", status: :see_other
    end

    # VENTAS DE UN PRODUCTO
    def product_sales
      @products = @product&.product_sales
    end

    # INVENTARIO
    def inventory
      base_scope = Product.where(kind: "producto")

      # Si viene un product_id específico por parámetro, filtramos directamente por él
      if params[:product_id].present?
        base_scope = base_scope.where(id: params[:product_id])
      elsif params[:query].present?
        q = params[:query].strip
        base_scope = base_scope.where(
          :code => /#{Regexp.escape(q)}/i
        ).or(Product.where(:name => /#{Regexp.escape(q)}/i))
      end

      # Manejo de estados de inventario (si no se busca un product_id específico)
      unless params[:product_id].present?
        @current_status = params[:status].presence || 'stock_bajo'
        
        case @current_status
        when 'stock_bajo'
          base_scope = base_scope.where(:quantity.lte => 15, :quantity.gt => 0) # Menor a 15 pero mayor a 0
        when 'agotados'
          base_scope = base_scope.where(:quantity.lte => 0) # Cero o negativos
        when 'todos'
          # No aplicamos filtro de cantidad
        end
      end

      totals = base_scope.collection.aggregate([
        { '$match' => base_scope.selector },
        {
          '$group' => {
            '_id' => nil,
            'total_cost' => { '$sum' => { '$multiply' => [{ '$ifNull': ['$cost_price', 0] }, { '$ifNull': ['$quantity', 0] }] } },
            'total_sale' => { '$sum' => { '$multiply' => [{ '$ifNull': ['$price', 0] }, { '$ifNull': ['$quantity', 0] }] } }
          }
        }
      ]).first

      @total_cost_all = totals ? totals['total_cost'].to_f : 0.0
      @total_sale_all = totals ? totals['total_sale'].to_f : 0.0

      respond_to do |format|
        format.html do
          @products = base_scope.order(name: :asc).page(params[:page]).per(15)
        end
        format.xlsx do
          @all_products = base_scope.order(name: :asc)
          render xlsx: 'inventory', filename: "Reporte_Inventario_#{Time.now.strftime('%Y%m%d_%H%M')}.xlsx"
        end
      end
    end

    # DEVUELTOS
    def devueltos
      @returned_products = ReturnedProduct.all
    end

    # BÚSQUEDA AJAX
    def search
      query = params[:q].to_s.strip

      products = if query.present?
                  Product.includes(:offer).where(name: /#{Regexp.escape(query)}/i).limit(10)
                else
                  Product.none
                end

      render json: products.map { |p|
        offer_obj = begin
                      if p.respond_to?(:offer) && p.offer.present?
                        p.offer
                      elsif p.respond_to?(:offer_id) && p.offer_id.present?
                        Offer.where(id: p.offer_id).first
                      end
                    rescue StandardError => e
                      Rails.logger.error "Error obteniendo oferta para producto #{p.id}: #{e.message}"
                      nil
                    end

        expires_at = p.try(:offer_expires_at)
        
        not_expired = if expires_at.blank?
                        offer_obj.present?
                      elsif expires_at.respond_to?(:to_date)
                        expires_at.to_date >= Date.current
                      else
                        expires_at > Time.current
                      end

        vigente = offer_obj.present? && not_expired

        offer_name = vigente ? (offer_obj.try(:name) || offer_obj.try(:nombre) || '') : ''
        type = vigente ? (offer_obj.try(:offer_type) || offer_obj.try(:tipo) || '') : ''

        {
          id: p.id.to_s,
          name: p.name,
          description: p.description,
          price: p.price.to_f,
          discount: vigente ? (p.try(:discount).to_f) : 0,
          offer_name: offer_name,
          offer_type: type,
          wholesale_quantity: (vigente && type.downcase == 'mayoreo') ? p.try(:wholesale_quantity).to_i : 0
        }
      }
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_current_user
      @current_user = current_user
    end

    def product_params
      params.require(:product).permit(
        :kind, :name, :description, :quantity, :price, :cost_price, :category_id, :marca_id, :discount, :code,
        :offer_type, :offer_id, :offer_expires_at, :wholesale_quantity, :car_type_id, :supplier_id,
        product_images_attributes: [:id, :title, :image_url, :file, :image_index, :_destroy]
      )
    end
  end
end