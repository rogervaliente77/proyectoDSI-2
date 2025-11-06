module Admin
  class ReportsController < Admin::ApplicationController
    layout 'dashboard'

    # ======================================================
    # 🔹 Reporte de productos más vendidos
    # ======================================================
    def top_products
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
      end_date   = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

      pipeline = [
        { "$match" => { "created_at" => { "$gte" => start_date.beginning_of_day, "$lte" => end_date.end_of_day } } },
        { "$group" => {
            "_id" => { "product_id" => "$product_id", "date" => { "$dateToString" => { "format" => "%Y-%m-%d", "date" => "$created_at" } } },
            "total_sold" => { "$sum" => "$quantity" },
            "total_revenue" => { "$sum" => { "$multiply" => ["$unit_price", "$quantity"] } }
          }
        },
        { "$lookup" => { "from" => "products", "localField" => "_id.product_id", "foreignField" => "_id", "as" => "product" } },
        { "$unwind" => "$product" },
        { "$project" => {
            "product_id" => "$product._id",
            "code" => "$product.code",
            "name" => "$product.name",
            "date" => "$_id.date",
            "total_sold" => 1,
            "total_revenue" => 1
          }
        },
        { "$sort" => { "total_sold" => -1, "date" => 1 } }
      ]

      @products_sales = ProductSale.collection.aggregate(pipeline).to_a rescue []
      @products_sales ||= []

      @chart_data = @products_sales.each_with_object({}) do |r, hash|
        hash[r["date"]] ||= 0
        hash[r["date"]] += r["total_sold"]
      end
    rescue => e
      Rails.logger.error("Error en top_products: #{e.message}")
      @products_sales = []
      @chart_data = {}
    end

    # ======================================================
    # 🔹 Reporte de marcas más vendidas
    # ======================================================
    def top_brands
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
      end_date   = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

      pipeline = [
        { "$match" => { "created_at" => { "$gte" => start_date.beginning_of_day, "$lte" => end_date.end_of_day } } },
        { "$lookup" => { "from" => "products", "localField" => "product_id", "foreignField" => "_id", "as" => "product" } },
        { "$unwind" => "$product" },
        { "$lookup" => { "from" => "marcas", "localField" => "product.marca_id", "foreignField" => "_id", "as" => "marca" } },
        { "$unwind" => { "path" => "$marca", "preserveNullAndEmptyArrays" => true } },
        { "$group" => {
            "_id" => { "brand_name" => { "$ifNull" => ["$marca.name", "Sin Marca"] }, "date" => { "$dateToString" => { "format" => "%Y-%m-%d", "date" => "$created_at" } } },
            "total_sold" => { "$sum" => "$quantity" },
            "total_revenue" => { "$sum" => { "$multiply" => ["$unit_price", "$quantity"] } }
          }
        },
        { "$sort" => { "total_sold" => -1, "_id.date" => 1 } }
      ]

      @brands_sales = ProductSale.collection.aggregate(pipeline).to_a rescue []
      @brands_sales ||= []
      @total_units_sold = @brands_sales.sum { |b| b["total_sold"] || 0 }
      @total_revenue = @brands_sales.sum { |b| b["total_revenue"] || 0 }
    rescue => e
      Rails.logger.error("Error en top_brands: #{e.message}")
      @brands_sales = []
      @total_units_sold = 0
      @total_revenue = 0
    end

    # ======================================================
    # 🔹 Reporte de mejores vendedores
    # ======================================================
    def best_seller
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : nil
      end_date   = params[:end_date].present? ? Date.parse(params[:end_date]) : nil

      match_stage = {}
      if start_date && end_date
        match_stage["created_at"] = { "$gte" => start_date.beginning_of_day, "$lte" => end_date.end_of_day }
      end

      pipeline = []
      pipeline << { "$match" => match_stage } unless match_stage.empty?

      pipeline += [
        { "$lookup" => { "from" => "sales", "localField" => "sale_id", "foreignField" => "_id", "as" => "sale" } },
        { "$unwind" => { "path" => "$sale", "preserveNullAndEmptyArrays" => true } },
        { "$lookup" => { "from" => "cajeros", "localField" => "sale.cajero_id", "foreignField" => "_id", "as" => "cajero" } },
        { "$unwind" => { "path" => "$cajero", "preserveNullAndEmptyArrays" => true } },
        { "$lookup" => { "from" => "users", "localField" => "cajero.user_id", "foreignField" => "_id", "as" => "usuario" } },
        { "$unwind" => { "path" => "$usuario", "preserveNullAndEmptyArrays" => true } },
        { "$group" => {
            "_id" => { "vendedor_nombre" => { "$ifNull" => ["$usuario.full_name", "Cajero en línea"] }, "date" => { "$dateToString" => { "format" => "%Y-%m-%d", "date" => "$created_at" } } },
            "total_sold" => { "$sum" => "$quantity" },
            "total_revenue" => { "$sum" => { "$multiply" => ["$unit_price", "$quantity"] } }
          }
        },
        { "$sort" => { "total_sold" => -1, "_id.date" => 1 } }
      ]

      @sellers_sales = ProductSale.collection.aggregate(pipeline).to_a rescue []
      @sellers_sales ||= []

      @total_units_sold = @sellers_sales.sum { |s| s["total_sold"] || 0 }
      @total_revenue    = @sellers_sales.sum { |s| s["total_revenue"] || 0 }
    rescue => e
      Rails.logger.error("Error en best_seller: #{e.message}")
      @sellers_sales = []
      @total_units_sold = 0
      @total_revenue = 0
    end

    # ======================================================
    # 🔹 Detalle de ventas de un vendedor en un día (JSON para modal)
    # ======================================================
     def seller_details
      vendedor_nombre = params[:vendedor]
      fecha = Date.parse(params[:fecha])
      start_time = fecha.beginning_of_day
      end_time   = fecha.end_of_day

      # Buscar usuario según nombre del vendedor
      user = User.where(full_name: vendedor_nombre).first

      # Si no hay usuario, devolver vacío
      return render json: { ventas: [] } unless user

      # Obtener todas las ventas del usuario en ese día
      sales = Sale.where(user_id: user.id, sold_at: start_time..end_time)

      # Combinar productos de todas las ventas y agrupar por producto
      ventas_agrupadas = sales.flat_map(&:product_sales)
                              .group_by { |ps| ps.product.name }
                              .map do |producto_nombre, ps_list|
                                total_cantidad = ps_list.sum(&:quantity)
                                unit_price     = ps_list.first.unit_price
                                subtotal       = ps_list.sum(&:subtotal)
                                {
                                  fecha: ps_list.first.sale.sold_at.strftime("%d/%m/%Y, %H:%M:%S"),
                                  producto: producto_nombre,
                                  cantidad: total_cantidad,
                                  precio_unitario: unit_price,
                                  subtotal: subtotal
                                }
                              end

      # Ordenar por cantidad descendente
      ventas_agrupadas.sort_by! { |v| -v[:cantidad] }

      render json: { ventas: ventas_agrupadas }
    rescue => e
      Rails.logger.error("Error en seller_details: #{e.message}")
      render json: { ventas: [] }
    end
  end
end
  
