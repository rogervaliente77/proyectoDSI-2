class UserSection
  # include Mongoid::Document
  # include Mongoid::Timestamps
  field :session_token, type: String
  field :expiration_time, type: DateTime
  field :user_id, type: BSON::ObjectId
  field :user_email, type: String
 
  has_one :user, inverse_of: :user_session
end
