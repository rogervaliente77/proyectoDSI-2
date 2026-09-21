# app/models/head_movimiento_caja.rb
class HeadMovimientoCaja
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos de trazabilidad del origen y montos
  field :comprobante_codigo, type: String
  field :origen_tipo, type: String          # "VentaProducto", "VentaServicio", etc.
  field :origen_id, type: BSON::ObjectId
  field :fecha, type: DateTime
  field :monto_total, type: Float, default: 0.0

  # Clasificación de montos según la condición tributaria
  field :total_gravado, type: Float, default: 0.0
  field :total_exento, type: Float, default: 0.0
  field :total_no_sujeta, type: Float, default: 0.0

  # Datos del cliente para DTE
  field :client_name, type: String
  field :tipo_documento_cliente, type: String
  field :num_documento_cliente, type: String
  field :nrc_cliente, type: String
  field :email_cliente, type: String
  field :telefono_cliente, type: String
  field :direccion_cliente, type: String

  # Facturación Electrónica (DTE)
  field :correlativo_documento, type: Integer
  field :numero_control, type: String
  field :codigo_generacion, type: String
  field :sello_recepcion, type: String

  # Relaciones
  belongs_to :client, optional: true
  belongs_to :sucursal, optional: true
  belongs_to :caja, optional: true
  belongs_to :cajero, optional: true
  belongs_to :user, optional: true
  belongs_to :tipo_documento_dte, class_name: "TipoDocumentoDte", optional: true
  belongs_to :sale, optional: true

  has_many :det_movimientos_caja, class_name: "DetMovimientoCaja", dependent: :destroy, inverse_of: :head_movimiento_caja

  before_create :set_defaults_and_generate_dte

  private

  def set_defaults_and_generate_dte
    self.fecha ||= Time.current
    self.codigo_generacion ||= SecureRandom.uuid.upcase

    return if numero_control.present?

    cod_sucursal = sucursal&.codigo.present? ? sucursal.codigo.rjust(4, '0') : "0000"
    num_caja = caja&.caja_number.present? ? caja.caja_number.to_s.rjust(3, '0') : "001"
    punto_venta = "P#{num_caja}"
    cod_dte = tipo_documento_dte&.codigo.presence || "00"

    if cod_dte == "00"
      self.correlativo_documento = nil
      self.numero_control = "REC-#{Time.current.to_i}"
      return
    end

    ultimo_correlativo = HeadMovimientoCaja.where(
      sucursal_id: sucursal_id,
      caja_id: caja_id,
      tipo_documento_dte_id: tipo_documento_dte_id
    ).max(:correlativo_documento) || 0

    self.correlativo_documento = ultimo_correlativo + 1
    correlativo_padded = self.correlativo_documento.to_s.rjust(15, '0')
    self.numero_control = "DTE-#{cod_dte}-#{cod_sucursal}#{punto_venta}-#{correlativo_padded}"
  end
end