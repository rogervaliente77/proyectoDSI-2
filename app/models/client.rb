class Client
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre, type: String
  field :telefono, type: String
  field :email, type: String
  field :is_active, type: Boolean, default: true

  has_many :client_cars, dependent: :destroy
end