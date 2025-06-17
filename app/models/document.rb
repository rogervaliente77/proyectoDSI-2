class Document
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :url, type: String
  field :doc_type, type: String
  field :uploaded_by_id, type: BSON::ObjectId
  field :uploaded_by_email, type: String
  field :status_count, type: Integer
  field :logs, type: Array
  field :user_ids, type: Array, default: []
  field :filename, type: String
  field :correlative_code, type: String
  field :correlative, type: Integer, default: 0

  before_create :set_correlative_values

  private

  def set_correlative_values
    last_doc = Document.order_by(created_at: :desc).where(:correlative.ne => nil).first

    self.correlative = last_doc.present? ? last_doc.correlative.to_i + 1 : 1
    self.correlative_code = "doc-#{Time.now.year}-#{self.correlative}"
  end
end
