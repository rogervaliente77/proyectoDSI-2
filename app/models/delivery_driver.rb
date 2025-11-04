class DeliveryDriver
  include Mongoid::Document
  include Mongoid::Timestamps # Para created_at y updated_at automáticos

  belongs_to :user

  field :nombre, type: String
  field :transportation_type, type: String #motorcycle, car, bike, truck
  field :scoring, type: Integer
  field :disabled, type: Boolean, default: true
end