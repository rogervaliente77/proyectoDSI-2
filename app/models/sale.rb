# app/models/sale.rb
require 'securerandom'

class Sale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sold_at, type: DateTime
  field :client_name, type: String
  field :status, type: String, default: "completed"
  field :client_id, type: BSON::ObjectId
  field :total_amount, type: Float
  field :code, type: String                     # Código interno (V-2026-09-19-001)
  field :user_id, type: BSON::ObjectId

  # --- Campos para Facturación Electrónica (DTE El Salvador) ---
  field :correlativo_documento, type: Integer  # Ej: 125 (Guardado en entero como pides)
  field :numero_control, type: String          # Ej: DTE-01-0001P001-000000000000125
  field :codigo_generacion, type: String        # UUID v4 (36 caracteres)
  field :sello_recepcion, type: String         # Otorgado por el MH tras recepción
  
  field :delivery_method, type: String
  field :was_delivered, type: Boolean, default: false
  field :delivered_at, type: DateTime

  # Relaciones
  belongs_to :sucursal, optional: true
  belongs_to :tipo_documento_dte, class_name: "TipoDocumentoDte", optional: true
  belongs_to :caja, class_name: "Caja", inverse_of: :sales, optional: true
  belongs_to :cajero, class_name: "Cajero", inverse_of: :sales, optional: true
  belongs_to :user, optional: true

  has_many :product_sales, class_name: "ProductSale", inverse_of: :sale, dependent: :destroy
  has_many :devoluciones, class_name: "Devolucion", inverse_of: :sale, dependent: :destroy
  has_one :delivery

  accepts_nested_attributes_for :product_sales, allow_destroy: true

  # Validaciones para evitar duplicados en producción
  validates :code, uniqueness: true, allow_blank: true
  validates :numero_control, uniqueness: true, allow_blank: true

  before_create :set_defaults_and_generate_dte

  private

  def set_defaults_and_generate_dte
    self.sold_at ||= Time.current
    generate_internal_code
    generate_dte_fields
  end

  def generate_internal_code
    return if code.present?

    prefix = 'V'
    date_str = Date.today.strftime("%Y-%m-%d")
    count_today = Sale.where(
      :created_at.gte => Date.today.beginning_of_day,
      :created_at.lt  => Date.today.end_of_day
    ).count

    self.code = "#{prefix}-#{date_str}-#{(count_today + 1).to_s.rjust(3, '0')}"
  end

  def generate_dte_fields
    return if numero_control.present?

    # 1. Asegurar asignación de sucursal
    self.sucursal ||= caja&.sucursal

    # 2. Asignar UUID v4 estándar de Hacienda
    self.codigo_generacion = SecureRandom.uuid.upcase

    # 3. Formatear Sucursal (4 dígitos) y Punto de Venta/Caja (P + 3 dígitos)
    cod_sucursal = sucursal&.codigo.present? ? sucursal.codigo.rjust(4, '0') : "0000"
    num_caja = caja&.caja_number.present? ? caja.caja_number.to_s.rjust(3, '0') : "001"
    punto_venta = "P#{num_caja}" # Ej: P001

    # 4. Obtener el código del tipo de DTE (Ej: "01", "03")
    cod_dte = tipo_documento_dte&.codigo.presence || "00"

    # Si es Recibo sin DTE ("00"), no genera correlativo DTE
    if cod_dte == "00"
      self.correlativo_documento = nil
      self.numero_control = "REC-#{code}"
      return
    end

    # 5. Obtener el último correlativo numérico registrado para este (Tipo DTE + Sucursal + Caja)
    ultimo_correlativo = Sale.where(
      sucursal_id: sucursal_id,
      caja_id: caja_id,
      tipo_documento_dte_id: tipo_documento_dte_id
    ).max(:correlativo_documento) || 0

    # Incrementar el correlativo numérico
    self.correlativo_documento = ultimo_correlativo + 1

    # 6. Formatear a 15 dígitos con ceros a la izquierda segun estándar DTE
    correlativo_padded = self.correlativo_documento.to_s.rjust(15, '0')

    # Resultado final guardado en `numero_control`: DTE-01-0001P001-000000000000125
    self.numero_control = "DTE-#{cod_dte}-#{cod_sucursal}#{punto_venta}-#{correlativo_padded}"
  end
end