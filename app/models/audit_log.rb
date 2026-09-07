# app/models/audit_log.rb
class AuditLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :auditable_type, type: String
  field :auditable_id,   type: BSON::ObjectId
  field :action,         type: String, default: "update"
  field :user_id,        type: BSON::ObjectId
  field :modifications,  type: Array, default: []

  belongs_to :user, optional: true

  def auditable
    auditable_type.constantize.find(auditable_id) rescue nil
  end
end