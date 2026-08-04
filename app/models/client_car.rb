class ClientCar
  include Mongoid::Document
  include Mongoid::Timestamps

  field :marca, type: String
  field :modelo, type: String
  field :anio, type: Integer
  field :color, type: String
  field :placa, type: String
  field :vin, type: String
  field :is_active, type: Boolean, default: true

  belongs_to :client
  has_many :service_orders, dependent: :destroy
end