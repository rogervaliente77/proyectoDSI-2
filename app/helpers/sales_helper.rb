module SalesHelper
  def format_sale_status(status)
    case status
    when 'pending_payment_comprob'
      'Pendiente de Comprobante'
    when 'pending_check_payment_comprob'
      'Comprobante en Revisión'
    when 'payment_approved'
      'Pago Aprobado'
    when 'preparing'
      'En Preparación'
    when 'pending_to_pickup'
      'Listo para Recoger'
    when 'assigned'
      'Mensajero Asignado'
    when 'on_route'
      'En Camino'
    when 'on_place'
      'En el Lugar de destino'
    when 'delivered', 'completed', 'picked_up'
      'Entregado'
    when 'cancelled'
      'Cancelado'
    else
      status.to_s.titleize
    end
  end

  def format_sale_payment_status(payment_status)
    case payment_status
    when 'pending'
      'Pendiente'
    when 'paid'
      'Pagado'
    else
      payment_status.to_s.titleize
    end
  end
end