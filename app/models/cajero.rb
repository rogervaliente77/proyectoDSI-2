class Cajero < ApplicationRecord
  belongs_to :caja
  belongs_to :user
end
