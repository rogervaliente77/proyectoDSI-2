class UserSession
  include Mongoid::Document
  include Mongoid::Timestamps

  field :session_token, type: String
  field :expiration_time, type: DateTime
  field :user_email, type: String

  belongs_to :user, class_name: "User", inverse_of: :user_sessions, optional: false

  index({ user_id: 1 })
end
