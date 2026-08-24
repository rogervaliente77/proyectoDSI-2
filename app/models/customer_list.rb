class CustomerList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  # Guardará un arreglo de hashes: [{ "id" => "...", "email" => "..." }]
  field :clients_data, type: Array, default: []

  has_many :email_templates

  validates :name, presence: true

  # Obtiene los registros reales de Client a partir de los IDs guardados
  def clients
    client_ids = clients_data.map { |c| c['id'] || c[:id] }.compact
    Client.where(:id.in => client_ids)
  end

  # Helper para obtener directamente la lista de correos
  def emails
    clients_data.map { |c| c['email'] || c[:email] }.compact
  end
end