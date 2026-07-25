class PlantillaVehiculo
  include Mongoid::Document
  include Mongoid::Timestamps

  field :numero_correlativo, type: Integer
  field :tipo, type: String
  field :marca, type: String
  field :modelo, type: String
  field :anio, type: Integer
  field :placa, type: String

  validates :placa, presence: true, uniqueness: true

  # Método para precargar la flota inicial si la colección está vacía
  def self.cargar_iniciales!
    return if count > 0

    datos = [
      { numero_correlativo: 1,  tipo: "PICK UP",     marca: "MAZDA",           modelo: "B2900 4X4 MID", anio: 2006, placa: "N-16981" },
      { numero_correlativo: 2,  tipo: "PICK UP",     marca: "MAZDA",           modelo: "BT 50 4X4",     anio: 2013, placa: "N-5064" },
      { numero_correlativo: 3,  tipo: "PICK UP",     marca: "MAZDA",           modelo: "BT 50 4X4",     anio: 2014, placa: "N-8764" },
      { numero_correlativo: 4,  tipo: "PICK UP",     marca: "MAZDA",           modelo: "BT 50 4X4",     anio: 2014, placa: "N-8765" },
      { numero_correlativo: 5,  tipo: "PICK UP",     marca: "MAZDA",           modelo: "BT 50 4X4",     anio: 2014, placa: "N-8766" },
      { numero_correlativo: 6,  tipo: "PICK UP",     marca: "MAZDA",           modelo: "BT 50 4X2",     anio: 2016, placa: "N-13157" },
      { numero_correlativo: 7,  tipo: "SEDAN",       marca: "NISSAN",          modelo: "DX GS2 1.6L",   anio: 2015, placa: "N-13150" },
      { numero_correlativo: 8,  tipo: "SEDAN",       marca: "NISSAN",          modelo: "DX GS2 1.6L",   anio: 2015, placa: "N-13157" },
      { numero_correlativo: 9,  tipo: "MOTOCICLETA", marca: "YAMAHA",          modelo: "YBR 125 ED",    anio: 2015, placa: "M-466807" },
      { numero_correlativo: 10, tipo: "MICROBUS",    marca: "HYUNDAI",         modelo: "COUNTRY",       anio: 2020, placa: "N-18443" },
      { numero_correlativo: 11, tipo: "PICK UP",     marca: "NP 300 FRONTIER", modelo: "NISSAN",        anio: 2021, placa: "N-18000" },
      { numero_correlativo: 12, tipo: "PICK UP",     marca: "NP 300 FRONTIER", modelo: "NISSAN",        anio: 2021, placa: "P-559D" },
      { numero_correlativo: 13, tipo: "PICK UP",     marca: "JIM",             modelo: "REMAX 5",       anio: 2023, placa: "N-19418" },
      { numero_correlativo: 14, tipo: "CAMIONETA",   marca: "TOYOTA",          modelo: "COROLLA CROSS", anio: 2022, placa: "P-491E" }
    ]

    create!(datos)
  end
end