class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :department, type: String
  field :municipality, type: String
  field :street, type: String
  field :house, type: String
  field :reference, type: String

  belongs_to :user, inverse_of: :addresses

end
