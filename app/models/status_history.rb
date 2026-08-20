# app/models/status_history.rb
class StatusHistory
  include Mongoid::Document
  include Mongoid::Timestamps

  field :changed_at, type: DateTime, default: -> { Time.current }
  field :previous_status, type: String
  field :new_status, type: String
  field :changed_by, type: BSON::ObjectId
  field :reason, type: String

  embedded_in :supplier_invoice
end