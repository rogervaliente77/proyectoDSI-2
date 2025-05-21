class Prueba
  include Mongoid::Document
  include Mongoid::Timestamps
  field :nombre, type: String
  field :description, type: String
end
