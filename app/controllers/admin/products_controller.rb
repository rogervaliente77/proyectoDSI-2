# app/controllers/admin/products_controller.rb
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

      # Filtro por término de búsqueda (Nombre o Código)
      if params[:query].present?
        query_regex = /#{Regexp.escape(params[:query].strip)}/i
        @products = @products.any_of({ name: query_regex }, { code: query_regex })
      end

      # Filtro de Categoría con Jerarquía
      if params[:category_id].present?
        selected_category = Category.where(id: params[:category_id]).first
        if selected_category
          category_ids = selected_category.respond_to?(:self_and_descendant_ids) ? selected_category.self_and_descendant_ids : [selected_category.id]
          @products = @products.where(:category_id.in => category_ids)
        end
      end

      # Filtro de Marca
      if params[:marca_id].present?
        marca_id = BSON::ObjectId.legal?(params[:marca_id]) ? BSON::ObjectId.from_string(params[:marca_id]) : params[:marca_id]
        @products = @products.where(marca_id: marca_id)
      end

      # Filtro de Tipo de Vehículo
      if params[:car_type_id].present?
        car_type_id = BSON::ObjectId.legal?(params[:car_type_id]) ? BSON::ObjectId.from_string(params[:car_type_id]) : params[:car_type_id]
        @products = @products.where(car_type_id: car_type_id)
      end

      # Filtro de Precios
      if params[:min_price].present? || params[:max_price].present?
        min_price = params[:min_price].present? ? params[:min_price].to_f : 0
        max_price = params[:max_price].present? ? params[:max_price].to_f : Float::INFINITY
        @products = @products.where(:price.gte => min_price, :price.lte => max_price)
      end

      # Filtro de Oferta
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
    end

    # CREAR PRODUCTO
    def create
      @product = Product.new(product_params)
      if @product.save
        create_product_history(
          @product, 
          @product.producto? ? 0 : nil, 
          @product.producto? ? @product.quantity : nil, 
          "Creación de #{@product.kind}"
        )

        redirect_to admin_productos_path, notice: "Producto creado con éxito."
      else
        flash[:alert] = "Hubo un error al crear el producto"
        render :new, status: :unprocessable_entity
      end
    end

    # EDITAR PRODUCTO
    def edit
      @categories = Category.all
      @marcas = Marca.all
      @product.product_images.build if @product.product_images.empty?
    end

    # ACTUALIZAR PRODUCTO
    def update
      stock_before = @product.quantity.to_i
      price_before = @product.price

      if @product.update(product_params)
        # 1. Movimiento de inventario para Producto Físico
        if @product.producto? && product_params[:quantity].present? && product_params[:quantity].to_i != stock_before
          movement_type = product_params[:quantity].to_i > stock_before ? "Ingreso" : "Salida"
          create_product_history(@product, stock_before, @product.quantity, movement_type)

        # 2. Movimiento por cambio de tarifa para Servicio
        elsif @product.servicio? && product_params[:price].present? && product_params[:price].to_f != price_before
          create_product_history(@product, nil, nil, "Ajuste de tarifa ($#{price_before} -> $#{@product.price})")
        end

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
      # 1. Base query
      base_scope = Product.where(kind: "producto")

      # 2. Búsqueda por query
      if params[:query].present?
        q = params[:query].strip
        base_scope = base_scope.where(
          :code => /#{Regexp.escape(q)}/i
        ).or(Product.where(:name => /#{Regexp.escape(q)}/i))
      end

      # 3. Filtro por estado
      @current_status = params[:status].presence || 'stock_bajo'
      base_scope = base_scope.where(:quantity.lte => 15) if @current_status == 'stock_bajo'

      # 4. Agregación de Totales Globales
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
                    Product.where(name: /#{Regexp.escape(query)}/i).limit(10)
                  else
                    Product.none
                  end
    
        render json: products.map { |p|
        vigente = p.offer_expires_at.present? && p.offer_expires_at > Time.current
      
        {
          id: p.id.to_s,
          name: p.name,
          description: p.description,
          price: p.price,
          discount: p.discount,
          offer_type: vigente ? p.offer_type : '',
          wholesale_quantity: (vigente && p.offer_type == 'mayoreo') ? p.wholesale_quantity : ''
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
        :offer_type, :offer_expires_at, :wholesale_quantity, :car_type_id,
        product_images_attributes: [:id, :title, :image_url, :file, :image_index, :_destroy] # <-- Se agregó :file
      )
    end
      
    def create_product_history(product, stock_before, stock_after, movement_type)
      ProductHistory.create!(
        product: product,
        name: product.name,
        description: product.description,
        code: product.code,
        quantity: product.producto? ? product.quantity : 0,
        price: product.price,
        discount: product.discount,
        stock_before: stock_before,
        current_stock: stock_after,
        movement_type: movement_type,
        user_id: @current_user.id
      )
    end
  end
end