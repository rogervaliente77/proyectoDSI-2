class Caja
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :sucursal, optional: true
  has_many :cajeros

  field :nombre, type: String
  field :caja_number, type: Integer

  validates :nombre, presence: true
  validates :caja_number, presence: true, numericality: { only_integer: true }
end