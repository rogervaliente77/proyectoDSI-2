class Categoria
  include Mongoid::Document
  include Mongoid::Timestamps

  field :nombre, type: String       # Ej: "Sistema Eléctrico", "Frenos"
  field :descripcion, type: String  # Ej: "Mantenimiento preventivo y correctivo..."
end