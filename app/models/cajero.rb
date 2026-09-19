class Cajero
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :sucursal, optional: true
  belongs_to :caja, optional: true
  belongs_to :user

  field :nombre, type: String

  validates :nombre, presence: true
end