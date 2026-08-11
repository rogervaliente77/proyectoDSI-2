class CarType
    include Mongoid::Document
    include Mongoid::Timestamps
  
    field :name, type: String
    field :description, type: String
  
    has_many :products
  
    validates :name, presence: true, uniqueness: { case_sensitive: false }
  
    before_save :uppercase_name
  
    private
  
    def uppercase_name
      self.name = name.strip.upcase if name.present?
    end
end