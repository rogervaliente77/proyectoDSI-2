# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_update :log_update_changes
  end

  attr_accessor :current_modifier

  private

  def log_update_changes
    ignored_fields = %w[updated_at created_at]

    # Obtenemos los cambios detectados por Mongoid
    raw_changes = previous_changes.presence || changes
    changes_to_record = raw_changes.except(*ignored_fields)

    return if changes_to_record.empty?

    changes_array = []

    changes_to_record.each do |field_name, values|
      old_val, new_val = values

      # Normalizamos valores vacíos "" a nil para evitar falsos negativos en BSON
      old_val = nil if old_val.blank?
      new_val = nil if new_val.blank?

      # Si ambos valores son idénticos tras la limpieza, ignoramos
      next if old_val.to_s == new_val.to_s

      # 1. Manejo de relaciones (llaves foráneas _id)
      if field_name.end_with?("_id")
        relation_changes = parse_belongs_to_change(field_name, old_val, new_val)
        changes_array << relation_changes if relation_changes.present?

      # 2. Manejo de imágenes embebidas
      elsif field_name == "product_images" && old_val.is_a?(Array) && new_val.is_a?(Array)
        image_changes = parse_product_images_changes(old_val, new_val)
        changes_array.concat(image_changes)

      # 3. Campos normales (Texto, Números, Fechas)
      else
        changes_array << {
          "campo"          => humanize_field_name(field_name),
          "valor_anterior" => format_field_value(old_val),
          "valor_nuevo"    => format_field_value(new_val)
        }
      end
    end

    return if changes_array.empty?

    AuditLog.create!(
      auditable_type: self.class.name,
      auditable_id:   self.id,
      action:         "update",
      user_id:        current_modifier&.id,
      modifications:  changes_array
    )
  end

  # Traduce las llaves foráneas (_id) a nombres legibles
  def parse_belongs_to_change(field_name, old_id, new_id)
    assoc_name = field_name.sub(/_id$/, "")
    
    # Comprobación estricta para evitar procesar si ambos eran equivalentes (ej: BSON vs String)
    return nil if old_id.to_s == new_id.to_s

    old_label = fetch_record_label(assoc_name, old_id)
    new_label = fetch_record_label(assoc_name, new_id)

    {
      "campo"          => humanize_field_name(assoc_name),
      "valor_anterior" => old_label,
      "valor_nuevo"    => new_label
    }
  end

  # Obtiene el campo 'name' o 'business_name' de Supplier/Category/Marca/etc.
  def fetch_record_label(assoc_name, record_id)
    return "Sin asignar" if record_id.blank?

    # Manejo explícito para clases especiales si el 'camelize' no coincide
    model_class = case assoc_name
                  when "supplier" then Supplier
                  when "category" then Category
                  when "marca"    then Marca
                  when "car_type" then CarType
                  else
                    assoc_name.camelize.constantize rescue nil
                  end

    return record_id.to_s unless model_class

    # Búsqueda segura en MongoDB por BSON::ObjectId
    bson_id = BSON::ObjectId.legal?(record_id.to_s) ? BSON::ObjectId.from_string(record_id.to_s) : record_id
    record  = model_class.where(id: bson_id).first

    return record_id.to_s unless record

    # Devuelve el nombre comercial o razón social en el caso de Supplier
    record.try(:name) || 
      record.try(:business_name) || 
      record.try(:title) || 
      record.try(:full_name) || 
      record_id.to_s
  end

  # Detecta cambios en las imágenes
  def parse_product_images_changes(old_list, new_list)
    diffs = []
    
    if new_list.size > old_list.size
      diffs << {
        "campo"          => "Imágenes del producto",
        "valor_anterior" => "#{old_list.size} imagen(es)",
        "valor_nuevo"    => "Se agregaron imágenes (#{new_list.size} en total)"
      }
    elsif new_list.size < old_list.size
      diffs << {
        "campo"          => "Imágenes del producto",
        "valor_anterior" => "#{old_list.size} imagen(es)",
        "valor_nuevo"    => "Se eliminaron imágenes (#{new_list.size} en total)"
      }
    else
      diffs << {
        "campo"          => "Imágenes del producto",
        "valor_anterior" => "Orden/Index previo",
        "valor_nuevo"    => "Se reordenaron las imágenes"
      }
    end

    diffs
  end

  # Nombres legibles para la interfaz
  def humanize_field_name(field_name)
    dictionary = {
      "name"               => "Nombre",
      "description"        => "Descripción",
      "quantity"           => "Stock",
      "price"              => "Precio Venta",
      "cost_price"         => "Precio Compra",
      "code"               => "Código",
      "discount"           => "Descuento (%)",
      "offer_type"         => "Tipo de Oferta",
      "offer_expires_at"   => "Expiración de Oferta",
      "wholesale_quantity" => "Cantidad Mayoreo",
      "wholesale_price"    => "Precio Mayoreo",
      "kind"               => "Tipo (Producto/Servicio)",
      "category"           => "Categoría",
      "supplier"           => "Proveedor",
      "marca"              => "Marca",
      "car_type"           => "Tipo de Vehículo"
    }

    dictionary[field_name] || field_name.humanize
  end

  def format_field_value(value)
    case value
    when Time, DateTime
      value.strftime("%d/%m/%Y %I:%M %p")
    when nil, ""
      "Vacío"
    else
      value
    end
  end
end