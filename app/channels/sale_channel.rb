class SaleChannel < ApplicationCable::Channel
  def subscribed
    if params[:sale_id].present?
      sale = Sale.find(params[:sale_id])
      stream_for sale
    else
      stream_from "admin_online_sales"
    end
  end

  def unsubscribed
    stop_all_streams
  end
end