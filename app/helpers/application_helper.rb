# app/helpers/application_helper.rb
module ApplicationHelper
  def status_badge_class(status)
    case status.to_s.downcase
    when 'pagada'
      'success'      # Verde
    when 'parcial'
      'info'         # Azul claro
    when 'pendiente'
      'warning'      # Amarillo
    when 'vencida'
      'danger'       # Rojo
    else
      'secondary'    # Gris
    end
  end
end