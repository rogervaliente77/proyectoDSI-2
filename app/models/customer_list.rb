class CustomerList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  # Guardará un arreglo de hashes: [{ "id" => "...", "email" => "...", "name" => "..." }]
  field :clients_data, type: Array, default: []

  has_many :email_templates

  validates :name, presence: true

  # Callback opcional: sincroniza info de nombres/emails desde la colección Client antes de guardar
  before_save :refresh_clients_info

  # Obtiene los registros reales de Client a partir de los IDs guardados
  def clients
    client_ids = clients_data.map { |c| c['id'] || c[:id] }.compact
    Client.where(:id.in => client_ids)
  end

  # Helper para obtener directamente la lista de correos
  def emails
    clients_data.map { |c| c['email'] || c[:email] }.compact
  end

  # Helper para obtener la lista de nombres
  def names
    clients_data.map { |c| c['name'] || c[:name] || c['nombre'] || c[:nombre] }.compact
  end

  # Método manual para actualizar las listas existentes antiguas que no tenían el campo 'name'
  def self.sync_all_existing_lists!
    all.each(&:sync_clients_data!)
  end

  def sync_clients_data!
    refresh_clients_info
    save
  end

  private

  private

  def refresh_clients_info
    return if clients_data.blank?

    client_ids = clients_data.map { |c| c['id'] || c[:id] }.compact
    db_clients = Client.where(:id.in => client_ids).index_by { |c| c.id.to_s }

    self.clients_data = clients_data.map do |item|
      id_str = (item['id'] || item[:id]).to_s
      client = db_clients[id_str]

      if client
        client_name = client.try(:nombre) || "Sin nombre"

        {
          "id" => id_str,
          "email" => client.email,
          "name" => client_name
        }
      else
        item
      end
    end
  end
end