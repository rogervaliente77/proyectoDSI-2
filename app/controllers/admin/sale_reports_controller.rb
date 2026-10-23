module Admin
  class SaleReportsController < ApplicationController
    layout 'dashboard'

    def index
      # La vista carga vacía e instantánea sin consultas pesadas a la BD
    end

    def sales_data
      start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : 30.days.ago.beginning_of_day
      end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : Time.current.end_of_day
      report_type = params[:report_type] || 'general'
      sale_channel = params[:sale_channel] # 'all', 'online', 'manual'

      # Base query
      sales = Sale.where(:created_at.gte => start_date, :created_at.lte => end_date)
      #sales = sales.where(status: 'completed') if params[:only_completed] == 'true'

      if sale_channel == 'online'
        sales = sales.where(online_order: true)
      elsif sale_channel == 'manual'
        sales = sales.where(online_order: false)
      end

      case report_type
      when 'general'
        data = generate_general_report(sales)
      when 'top_products'
        data = generate_top_products_report(sales)
      when 'payment_methods'
        data = generate_payment_methods_report(sales)
      when 'logistics'
        data = generate_logistics_report(sales)
      when 'by_cashier'
        data = generate_by_cashier_report(sales)
      else
        data = {}
      end

      render json: data
    end

    private

    def generate_general_report(sales)
      # Agrupar ventas por fecha (Día)
      grouped = sales.group_by { |s| s.created_at.in_time_zone('America/El_Salvador').strftime('%d/%m/%Y') }

      labels = []
      online_totals = []
      manual_totals = []
      rows = []

      grouped.each do |date, day_sales|
        labels << date
        online_sum = day_sales.select(&:online_order).sum(&:total_amount)
        manual_sum = day_sales.reject(&:online_order).sum(&:total_amount)

        online_totals << online_sum.round(2)
        manual_totals << manual_sum.round(2)

        rows << {
          date: date,
          total_transactions: day_sales.count,
          online_amount: "$#{'%.2f' % online_sum}",
          manual_amount: "$#{'%.2f' % manual_sum}",
          total_amount: "$#{'%.2f' % (online_sum + manual_sum)}"
        }
      end

      {
        report_type: 'general',
        chart_data: {
          labels: labels,
          datasets: [
            { label: 'Ventas en Línea ($)', data: online_totals, backgroundColor: '#4e73df' },
            { label: 'Ventas Manuales ($)', data: manual_totals, backgroundColor: '#1cc88a' }
          ]
        },
        rows: rows,
        summary: {
          grand_total: "$#{'%.2f' % sales.sum(&:total_amount)}",
          total_count: sales.count,
          online_count: sales.where(online_order: true).count,
          manual_count: sales.where(online_order: false).count
        }
      }
    end

    def generate_top_products_report(sales)
      sale_ids = sales.pluck(:id)
      product_sales = ProductSale.where(:sale_id.in => sale_ids)

      # Agrupar por producto
      grouped = product_sales.group_by(&:product_id)

      labels = []
      quantities = []
      subtotals = []
      rows = []

      # Ordenar por cantidad vendida descendente
      sorted_groups = grouped.map do |product_id, items|
        product = Product.where(id: product_id).first
        qty = items.sum(&:quantity)
        subtotal = items.sum(&:subtotal)
        { product_name: product&.name || 'Producto Desconocido', qty: qty, subtotal: subtotal }
      end.sort_by { |item| item[:qty] }.reverse.first(10) # Top 10

      sorted_groups.each do |item|
        labels << item[:product_name]
        quantities << item[:qty]
        subtotals << item[:subtotal].round(2)

        rows << {
          product_name: item[:product_name],
          quantity: item[:qty],
          subtotal: "$#{'%.2f' % item[:subtotal]}"
        }
      end

      {
        report_type: 'top_products',
        chart_data: {
          labels: labels,
          datasets: [
            { label: 'Unidades Vendidas', data: quantities, backgroundColor: '#36b9cc' }
          ]
        },
        rows: rows
      }
    end

    def generate_payment_methods_report(sales)
      grouped = sales.group_by(&:forma_pago)
    
      labels = []
      totals = []
      rows = []
    
      grouped.each do |code, method_sales|
        # Busca la forma de pago por el código en el modelo correspondiente
        forma_pago_obj = FormaPago.where(codigo: code).first if code.present?
        
        # Toma exactamente el name (o ajusta el campo si en tu modelo se llama de otra forma, ej. :nombre)
        method_name = forma_pago_obj&.name || (code.present? ? "Código: #{code}" : 'No Especificado')
        
        sum = method_sales.sum(&:total_amount)
    
        labels << method_name
        totals << sum.round(2)
    
        rows << {
          method: method_name,
          count: method_sales.count,
          total: "$#{'%.2f' % sum}"
        }
      end
    
      {
        report_type: 'payment_methods',
        chart_data: {
          labels: labels,
          datasets: [
            { data: totals, backgroundColor: ['#4e73df', '#1cc88a', '#36b9cc', '#f6c23e', '#e74a3b'] }
          ]
        },
        rows: rows
      }
    end

    def generate_logistics_report(sales)
      online_sales = sales.where(online_order: true)
      grouped = online_sales.group_by(&:delivery_method)

      labels = []
      counts = []
      rows = []

      grouped.each do |method, method_sales|
        method_name = method == 'delivery' ? 'Envío a Domicilio' : 'Retiro en Taller (Pickup)'
        labels << method_name
        counts << method_sales.count

        rows << {
          method: method_name,
          count: method_sales.count,
          total_amount: "$#{'%.2f' % method_sales.sum(&:total_amount)}"
        }
      end

      {
        report_type: 'logistics',
        chart_data: {
          labels: labels,
          datasets: [
            { data: counts, backgroundColor: ['#4e73df', '#f6c23e'] }
          ]
        },
        rows: rows
      }
    end

    def generate_by_cashier_report(sales)
      # Si deseas incluir tanto ventas manuales como en línea que tengan cajero asignado, 
      # puedes omitir el filtro de online_order o ajustarlo según necesites.
      # Dejaremos todas las ventas que contengan cajero_id:
      sales_with_cashier = sales.where(:cajero_id.ne => nil)
      
      grouped = sales_with_cashier.group_by(&:cajero_id)
    
      labels = []
      totals = []
      rows = []
    
      grouped.each do |cajero_id, cashier_sales|
        # Buscamos directamente en tu modelo Cajero (ajusta el campo del nombre si en tu modelo se llama diferente, ej: :nombre o :name)
        cajero = Cajero.where(id: cajero_id).first
        cashier_name = cajero&.nombre || cajero&.name || 'Cajero No Asignado'
        
        sum = cashier_sales.sum(&:total_amount)
    
        labels << cashier_name
        totals << sum.round(2)
    
        rows << {
          cashier: cashier_name,
          count: cashier_sales.count,
          total: "$#{'%.2f' % sum}"
        }
      end
    
      {
        report_type: 'by_cashier',
        chart_data: {
          labels: labels,
          datasets: [
            { label: 'Ventas por Cajero ($)', data: totals, backgroundColor: '#1cc88a' }
          ]
        },
        rows: rows
      }
    end
  end
end