class ConferenceRegistration
  # include Mongoid::Document
  # include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :registered_at, type: DateTime
  field :status, type: String, default: "pending" # Valores posibles: "pending", "confirmed", "cancelled"

  belongs_to :user
  belongs_to :conference

  validates :user_id, presence: true
  validates :conference_id, presence: true
  # validates :status, inclusion: { in: %w[pending confirmed cancelled] }
end

# conference = Conference.new(
#   title: "Tech Conference 2025", 
#   description: "A conference on the latest in tech.", 
#   start_date: DateTime.new(2025, 5, 20, 9, 0, 0), 
#   end_date: DateTime.new(2025, 5, 22, 18, 0, 0), 
#   is_available: true, 
#   max_limit_of_attendees: 100, 
#   speaker_name: "Jane Smith", 
#   image_url: "https://plus.unsplash.com/premium_photo-1661342428515-5ca8cee4385a",
# )

# conference_registration = ConferenceRegistration.create(
#   name: "Walter", 
#   email: "epenate@hotmail.com", 
#   registered_at: Time.current, 
#   status: "pending", 
#   user_id: User.first.id,
#   conference_id: ObjectId("679d54b41957e166caec392f")
# )

# "_id" : ObjectId("679a5549822d70ed0f101e74"),
# "name" : "Walter",
# "email" : "epenate@hotmail.com",
# "password" : "123123",
# "password_confirmation" : "123123",