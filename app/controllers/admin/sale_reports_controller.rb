module Admin
  class SaleReportsController < ApplicationController
    layout 'dashboard'

    # Hacemos accesibles estos métodos para las vistas (.xlsx.axlsx)
    helper_method :generate_general_report, 
                  :generate_top_products_report, 
                  :generate_payment_methods_report, 
                  :generate_logistics_report, 
                  :generate_by_cashier_report

    def index
      # La vista carga vacía e instantánea sin consultas pesadas a la BD
    end

    def sales_data
      sales = filter_sales_by_params
      report_type = params[:report_type] || 'general'

      data = case report_type
             when 'general' then generate_general_report(sales)
             when 'top_products' then generate_top_products_report(sales)
             when 'payment_methods' then generate_payment_methods_report(sales)
             when 'logistics' then generate_logistics_report(sales)
             when 'by_cashier' then generate_by_cashier_report(sales)
             else {}
             end

      render json: data
    end

    def export_excel
      @sales = filter_sales_by_params
      @report_type = params[:report_type] || 'general'
      
      report_titles = {
        'general' => 'Ventas Generales (Canales)',
        'top_products' => 'Top 10 Productos Más Vendidos',
        'payment_methods' => 'Desglose por Métodos de Pago',
        'logistics' => 'Logística de Entregas (Online)',
        'by_cashier' => 'Ventas por Cajero / Usuario'
      }
      @report_title = report_titles[@report_type] || 'Reporte de Ventas'

      respond_to do |format|
        format.xlsx { 
          response.headers['Content-Disposition'] = "attachment; filename=Reporte_#{@report_type}_#{Time.current.strftime('%Y%m%d_%H%M')}.xlsx"
        }
      end
    end

    # 🔹 Movemos los generadores fuera de private para que el helper_method funcione correctamente, 
    # o los dejamos accesibles como métodos públicos del controlador.
    def generate_general_report(sales)
      sales_list = sales.to_a
      sale_ids = sales_list.map(&:id)

      # Devoluciones autorizadas agrupadas por sale_id
      authorized_returns = Devolucion.where(:sale_id.in => sale_ids, is_authorized: true)
      returns_by_sale_id = authorized_returns.group_by(&:sale_id).transform_values do |devs|
        {
          amount: devs.sum { |d| (d.total_a_devolver || 0).to_f },
          types: devs.map(&:tipo_devolucion).compact.uniq
        }
      end

      grouped = sales_list.group_by { |s| s.created_at.in_time_zone('America/El_Salvador').strftime('%d/%m/%Y') }

      labels = []
      online_totals = []
      manual_totals = []
      rows = []
      detailed_groups = []

      grand_returned_total = 0.0

      grouped.each do |date, day_sales|
        labels << date
        online_sum = day_sales.select(&:online_order).sum { |s| (s.total_amount || 0).to_f }
        manual_sum = day_sales.reject(&:online_order).sum { |s| (s.total_amount || 0).to_f }
        day_gross = online_sum + manual_sum

        day_returned = day_sales.sum { |s| returns_by_sale_id[s.id]&.dig(:amount) || 0.0 }
        day_net = day_gross - day_returned
        grand_returned_total += day_returned

        online_totals << online_sum.round(2)
        manual_totals << manual_sum.round(2)

        rows << {
          date: date,
          total_transactions: day_sales.count,
          online_amount: "$#{'%.2f' % online_sum}",
          manual_amount: "$#{'%.2f' % manual_sum}",
          returned_amount: "$#{'%.2f' % day_returned}",
          net_amount: "$#{'%.2f' % day_net}",
          total_amount: "$#{'%.2f' % day_gross}"
        }

        by_type = day_sales.group_by { |s| s.online_order ? 'En Línea' : 'Manual (Taller)' }
        type_details = by_type.map do |type_name, type_sales|
          {
            type_name: type_name,
            sales: type_sales.map do |s|
              ret_info = returns_by_sale_id[s.id]
              ret_amt = ret_info ? ret_info[:amount] : 0.0
              ret_types = ret_info ? ret_info[:types].join(', ') : ''

              {
                code: s.code,
                client_name: s.client_name || 'Sin cliente',
                total_amount: "$#{'%.2f' % ((s.total_amount || 0).to_f)}",
                returned_amount: "$#{'%.2f' % ret_amt}",
                has_return: ret_amt > 0,
                return_type: ret_types,
                status: s.status,
                payment_status: s.payment_status
              }
            end
          }
        end

        detailed_groups << {
          date: date,
          types: type_details
        }
      end

      grand_gross_total = sales_list.sum { |s| (s.total_amount || 0).to_f }
      grand_net_total = grand_gross_total - grand_returned_total

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
        detailed_groups: detailed_groups,
        summary: {
          grand_total: "$#{'%.2f' % grand_gross_total}",
          total_returned: "$#{'%.2f' % grand_returned_total}",
          net_total: "$#{'%.2f' % grand_net_total}",
          total_count: sales_list.count,
          online_count: sales_list.count(&:online_order),
          manual_count: sales_list.count { |s| !s.online_order }
        }
      }
    end

    
    def generate_top_products_report(sales)
      sales_list = sales.to_a
      sales_by_id = sales_list.index_by(&:id)
      sale_ids = sales_by_id.keys
      product_sales = ProductSale.where(:sale_id.in => sale_ids).to_a

      # Devoluciones autorizadas asociadas a las ventas del rango
      authorized_returns = Devolucion.where(:sale_id.in => sale_ids, is_authorized: true).to_a

      # Mapear devoluciones por [sale_id.to_s, product_id.to_s]
      returns_by_sale_and_product = Hash.new { |h, k| h[k] = { qty: 0, amount: 0.0 } }
      authorized_returns.each do |dev|
        s_key = dev.sale_id.to_s
        detalles = dev.respond_to?(:sale_devolucion_detalle) ? (dev.sale_devolucion_detalle || []) : []

        detalles.each do |det|
          h_det = det.respond_to?(:to_h) ? det.to_h : det
          p_id = (h_det['product_id'] || h_det[:product_id]).to_s
          next if p_id.blank?

          qty_dev = (h_det['cantidad'] || h_det[:cantidad] || 0).to_f
          precio_con_desc = h_det['precio_con_descuento'] || h_det[:precio_con_descuento]
          precio_unit = h_det['precio_unitario'] || h_det[:precio_unitario] || 0.0
          desc_unit = h_det['descuento'] || h_det[:descuento] || 0.0

          monto_dev = if !precio_con_desc.nil?
                        precio_con_desc.to_f * qty_dev
                      else
                        ((precio_unit.to_f - desc_unit.to_f) * qty_dev)
                      end

          entry = returns_by_sale_and_product[[s_key, p_id]]
          entry[:qty] += qty_dev
          entry[:amount] += monto_dev
        end
      end

      grouped = product_sales.group_by(&:product_id)

      labels = []
      quantities = []
      rows = []

      sorted_groups = grouped.map do |product_id, items|
        product = Product.where(id: product_id).first
        qty = items.sum { |ps| (ps.quantity || 0).to_f }
        subtotal = items.sum { |ps| (ps.subtotal || 0).to_f }

        prod_returned_qty = 0.0
        prod_returned_amount = 0.0

        sales_breakdown = items.map do |ps|
          sale = sales_by_id[ps.sale_id]
          ret = returns_by_sale_and_product[[ps.sale_id.to_s, product_id.to_s]]
          ret_qty = ret ? ret[:qty] : 0.0
          ret_amt = ret ? ret[:amount] : 0.0

          prod_returned_qty += ret_qty
          prod_returned_amount += ret_amt

          ps_sub = (ps.subtotal || 0).to_f
          ps_net = ps_sub - ret_amt

          {
            sale_code: sale&.code || 'N/A',
            date: sale&.created_at ? sale.created_at.in_time_zone('America/El_Salvador').strftime('%d/%m/%Y %H:%M') : 'N/A',
            client_name: sale&.client_name.presence || 'Sin cliente',
            channel: sale&.online_order ? 'En Línea' : 'Manual (Taller)',
            quantity: ps.quantity || 0,
            returned_qty: ret_qty == ret_qty.to_i ? ret_qty.to_i : ret_qty.round(2),
            returned_amount: "$#{'%.2f' % ret_amt}",
            has_return: ret_amt > 0 || ret_qty > 0,
            subtotal: "$#{'%.2f' % ps_sub}",
            net_subtotal: "$#{'%.2f' % ps_net}"
          }
        end

        net_subtotal = subtotal - prod_returned_amount

        {
          product_name: product&.name || 'Producto Desconocido',
          qty: qty == qty.to_i ? qty.to_i : qty.round(2),
          returned_qty: prod_returned_qty == prod_returned_qty.to_i ? prod_returned_qty.to_i : prod_returned_qty.round(2),
          returned_amount: prod_returned_amount,
          subtotal: subtotal,
          net_subtotal: net_subtotal,
          breakdown: sales_breakdown
        }
      end.sort_by { |item| item[:qty] }.reverse.first(5)

      sorted_groups.each do |item|
        labels << item[:product_name]
        quantities << item[:qty]

        rows << {
          product_name: item[:product_name],
          quantity: item[:qty],
          returned_qty: item[:returned_qty],
          returned_amount: "$#{'%.2f' % item[:returned_amount]}",
          has_return: item[:returned_amount] > 0 || item[:returned_qty] > 0,
          subtotal: "$#{'%.2f' % item[:subtotal]}",
          net_subtotal: "$#{'%.2f' % item[:net_subtotal]}",
          breakdown: item[:breakdown]
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
      sales_list = sales.to_a
      sale_ids = sales_list.map(&:id)

      authorized_returns = Devolucion.where(:sale_id.in => sale_ids, is_authorized: true).to_a
      returns_by_sale_id = authorized_returns.group_by(&:sale_id).transform_values do |devs|
        {
          amount: devs.sum { |d| (d.total_a_devolver || 0).to_f },
          types: devs.map(&:tipo_devolucion).compact.uniq
        }
      end

      grouped = sales_list.group_by(&:forma_pago)

      labels = []
      totals = []
      rows = []

      grouped.each do |code, method_sales|
        forma_pago_obj = FormaPago.where(codigo: code).first if code.present?
        method_name = forma_pago_obj&.name || (code.present? ? "Código: #{code}" : 'No Especificado')
        gross_sum = method_sales.sum { |s| (s.total_amount || 0).to_f }
        returned_sum = method_sales.sum { |s| returns_by_sale_id[s.id]&.dig(:amount) || 0.0 }
        net_sum = gross_sum - returned_sum

        labels << method_name
        totals << gross_sum.round(2)

        sales_list_data = method_sales.map do |s|
          ret_info = returns_by_sale_id[s.id]
          ret_amt = ret_info ? ret_info[:amount] : 0.0
          ret_types = ret_info ? ret_info[:types].join(', ') : ''
          sale_gross = (s.total_amount || 0).to_f
          sale_net = sale_gross - ret_amt

          {
            sale_code: s.code,
            date: s.created_at ? s.created_at.in_time_zone('America/El_Salvador').strftime('%d/%m/%Y %H:%M') : 'N/A',
            client_name: s.client_name.presence || 'Sin cliente',
            channel: s.online_order ? 'En Línea' : 'Manual (Taller)',
            status: s.status,
            total_amount: "$#{'%.2f' % sale_gross}",
            returned_amount: "$#{'%.2f' % ret_amt}",
            net_amount: "$#{'%.2f' % sale_net}",
            has_return: ret_amt > 0,
            return_type: ret_types
          }
        end

        rows << {
          method: method_name,
          count: method_sales.count,
          total: "$#{'%.2f' % gross_sum}",
          returned_amount: "$#{'%.2f' % returned_sum}",
          net_total: "$#{'%.2f' % net_sum}",
          sales: sales_list_data
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
      sales_with_cashier = sales.where(:cajero_id.ne => nil).to_a
      sale_ids = sales_with_cashier.map(&:id)

      authorized_returns = Devolucion.where(:sale_id.in => sale_ids, is_authorized: true).to_a
      returns_by_sale_id = authorized_returns.group_by(&:sale_id).transform_values do |devs|
        {
          amount: devs.sum { |d| (d.total_a_devolver || 0).to_f },
          types: devs.map(&:tipo_devolucion).compact.uniq
        }
      end

      grouped = sales_with_cashier.group_by(&:cajero_id)

      labels = []
      totals = []
      rows = []

      grouped.each do |cajero_id, cashier_sales|
        cajero = Cajero.where(id: cajero_id).first
        cashier_name = cajero&.nombre || cajero&.name || 'Cajero No Asignado'
        gross_sum = cashier_sales.sum { |s| (s.total_amount || 0).to_f }
        returned_sum = cashier_sales.sum { |s| returns_by_sale_id[s.id]&.dig(:amount) || 0.0 }
        net_sum = gross_sum - returned_sum

        labels << cashier_name
        totals << gross_sum.round(2)

        sales_list_data = cashier_sales.map do |s|
          ret_info = returns_by_sale_id[s.id]
          ret_amt = ret_info ? ret_info[:amount] : 0.0
          ret_types = ret_info ? ret_info[:types].join(', ') : ''
          sale_gross = (s.total_amount || 0).to_f
          sale_net = sale_gross - ret_amt

          {
            sale_code: s.code,
            date: s.created_at ? s.created_at.in_time_zone('America/El_Salvador').strftime('%d/%m/%Y %H:%M') : 'N/A',
            client_name: s.client_name.presence || 'Sin cliente',
            channel: s.online_order ? 'En Línea' : 'Manual (Taller)',
            status: s.status,
            total_amount: "$#{'%.2f' % sale_gross}",
            returned_amount: "$#{'%.2f' % ret_amt}",
            net_amount: "$#{'%.2f' % sale_net}",
            has_return: ret_amt > 0,
            return_type: ret_types
          }
        end

        rows << {
          cashier: cashier_name,
          count: cashier_sales.count,
          total: "$#{'%.2f' % gross_sum}",
          returned_amount: "$#{'%.2f' % returned_sum}",
          net_total: "$#{'%.2f' % net_sum}",
          sales: sales_list_data
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

    private

    def filter_sales_by_params
      start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : 30.days.ago.beginning_of_day
      end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : Time.current.end_of_day
      sale_channel = params[:sale_channel]

      sales = Sale.where(:created_at.gte => start_date, :created_at.lte => end_date)

      if sale_channel == 'online'
        sales = sales.where(online_order: true)
      elsif sale_channel == 'manual'
        sales = sales.where(online_order: false)
      end

      sales
    end
  end
end