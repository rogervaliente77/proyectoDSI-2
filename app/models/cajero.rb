class Cajero
  include Mongoid::Document
  include Mongoid::Timestamps # Para created_at y updated_at automáticos

  belongs_to :caja
  belongs_to :user

  field :nombre, type: String
end