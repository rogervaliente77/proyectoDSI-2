class UserSession < ApplicationRecord
  belongs_to :user

  # has_one :user, inverse_of: :user_session
  # En tu modelo User actual
  belongs_to :user_session, optional: true, inverse_of: :user

end
