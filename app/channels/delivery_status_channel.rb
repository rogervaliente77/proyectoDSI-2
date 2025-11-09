class DeliveryStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from "delivery_status_#{params[:delivery_id]}"
  end
end
