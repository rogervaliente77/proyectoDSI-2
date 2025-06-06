class UserSession < ApplicationRecord
  belongs_to :user

  has_one :user, inverse_of: :user_session
end
