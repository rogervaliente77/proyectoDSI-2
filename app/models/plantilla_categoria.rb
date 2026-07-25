class PlantillaCategoria
  include Mongoid::Document
  include Mongoid::Timestamps

  field :tipo_mantenimiento, type: String
  field :categoria, type: String
  field :descripcion_tareas, type: String
  field :items_defecto, type: Array, default: [] # Lista de nombres de items

  validates :categoria, presence: true, uniqueness: true

  def self.cargar_iniciales!
    # Si ya existen registros, actualizamos o evitamos duplicados
    return if count > 0

    datos = [
      {
        tipo_mantenimiento: "PREVENTIVO",
        categoria: "MANTENIMIENTO PREVENTIVO GENERAL",
        descripcion_tareas: "Mantenimiento preventivo requerido para vehículos cada 5,000 Km y para motocicletas cada 1,000 Km.",
        items_defecto: [
          "Cambio de aceite de motor y filtro de aceite",
          "Filtro de combustible (Diesel/Gasolina)",
          "Filtro de aire de motor",
          "Engrase de chasis, crucetas y puntos de fricción",
          "Alineado, balanceo y rotación de llantas",
          "Revisión y rellenado de fluidos (frenos, refrigerante, hidráulico)",
          "Revisión de sistema de encendido, fajas, mangueras y batería",
          "Lavado general y aspirado"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "MOTOR / GENERAL",
        descripcion_tareas: "Atención de fallas según recomendación del fabricante o desgaste.",
        items_defecto: [
          "Bujías / Candelas de incandescencia (Diesel)",
          "Líquido refrigerante / Coolant",
          "Empaque de punterías / tapaválvulas",
          "Faja de distribución / Kit de tiempo",
          "Faja de alternador y accesorios",
          "Soportes de motor (Frontal/Trasero/Lados)",
          "Bomba de agua y Termostato",
          "Alternador / Reparación de alternador"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "SISTEMA ELÉCTRICO",
        descripcion_tareas: "Diagnóstico y corrección de circuito eléctrico y batería.",
        items_defecto: [
          "Batería (Suministro e instalación)",
          "Terminales y cables de batería",
          "Alineado y cambio de luces principales (Faros)",
          "Luces secundarias (Vía, freno, retroceso, halógenos)",
          "Revisión / Reparación de motor de arranque"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "FRENOS",
        descripcion_tareas: "Sistema de frenado e hidráulico.",
        items_defecto: [
          "Pastillas de freno delanteras",
          "Zapatas / Pastillas de freno traseras",
          "Rectificación o reemplazo de discos de freno",
          "Bomba central de frenos",
          "Líquido de frenos DOT3/DOT4"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "TRANSMISIÓN",
        descripcion_tareas: "Sistema de embrague, caja de cambios y diferencial.",
        items_defecto: [
          "Kit de embrague (Disco, prensa y cojinete)",
          "Aceite de transmisión (Manual / Automática)",
          "Aceite de diferencial",
          "Bomba auxiliar / central de clutch",
          "Crucetas de barra de mando"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "DIRECCIÓN Y SUSPENSIÓN",
        descripcion_tareas: "Sistemas de amortiguación, estabilidad y dirección.",
        items_defecto: [
          "Amortiguadores delanteros",
          "Amortiguadores traseros",
          "Terminales de dirección y cremallera",
          "Bujes de muelles / suspensión",
          "Líquido de dirección hidráulica"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "AIRE ACONDICIONADO",
        descripcion_tareas: "Climatización y filtros de cabina.",
        items_defecto: [
          "Carga de gas refrigerante A/C R134a",
          "Filtro de aire de cabina",
          "Compresor de A/C",
          "Evaporador / Condensador"
        ]
      },
      {
        tipo_mantenimiento: "CORRECTIVO",
        categoria: "PINTURA",
        descripcion_tareas: "Enderezado y pintura por piezas.",
        items_defecto: [
          "Pintura y acabado de pieza grande",
          "Pintura y acabado de pieza mediana",
          "Pintura y acabado de pieza pequeña"
        ]
      }
    ]

    create!(datos)
  end
end