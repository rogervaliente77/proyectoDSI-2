class Caja
  include Mongoid::Document
  include Mongoid::Timestamps # Para created_at y updated_at automáticos

  field :nombre, type: String
  field :caja_number, type: Integer

  validates :nombre, presence: true
  validates :caja_number, presence: true, numericality: { only_integer: true }
end
