puts "Limpiando datos de proveedores y facturas..."
SupplierPayment.destroy_all rescue nil
SupplierInvoice.destroy_all rescue nil
Supplier.destroy_all rescue nil

puts "Creando Proveedores..."

suppliers_data = [
  {
    name: "Super Repuestos",
    business_name: "Super Repuestos S.A. de C.V.",
    nit_nrc: "0614-150880-101-2",
    phone: "2257-7777",
    email: "ventas@superrepuestos.com",
    address: "Bulevar Los Héroes #123, San Salvador",
    contact_person: "Carlos Mendoza",
    credit_days: 30,
    credit_limit: 10000.0,
    active: true
  },
  {
    name: "Impresa Repuestos",
    business_name: "Impresa Repuestos S.A. de C.V.",
    nit_nrc: "0614-200175-001-5",
    phone: "2231-5555",
    email: "contacto@impresarepuestos.com",
    address: "Alameda Roosevelt y 45 Av. Sur, San Salvador",
    contact_person: "Roberto Gómez",
    credit_days: 45,
    credit_limit: 15000.0,
    active: true
  },
  {
    name: "Disagro Repuestos",
    business_name: "Distribuidora Agroindustrial S.A.",
    nit_nrc: "0614-051192-102-8",
    phone: "2298-1234",
    email: "ventas.sv@disagro.com",
    address: "Carretera a Santa Ana Km 28, La Libertad",
    contact_person: "Ana Patricia Rivas",
    credit_days: 15,
    credit_limit: 5000.0,
    active: true
  },
  {
    name: "Autopartes El Globo",
    business_name: "El Globo Auto Parts S.A. de C.V.",
    nit_nrc: "0614-100288-103-1",
    phone: "2440-9988",
    email: "pedidos@elgloboautoparts.com",
    address: "25 Avenida Sur y Calle Gerardo Barrios, San Salvador",
    contact_person: "Luis Alberto Torres",
    credit_days: 30,
    credit_limit: 8000.0,
    active: true
  },
  {
    name: "Lubricantes y Filtros San José",
    business_name: "Comercializadora San José S.A.",
    nit_nrc: "0614-180401-002-9",
    phone: "2510-4321",
    email: "facturacion@lubrisanjose.com",
    address: "Calle 5 de Noviembre #405, San Salvador",
    contact_person: "Mariana Fuentes",
    credit_days: 60,
    credit_limit: 12000.0,
    active: true
  }
]

created_suppliers = suppliers_data.map do |s_data|
  Supplier.create!(s_data)
end

puts "¡5 Proveedores creados exitosamente!"
puts "Creando Facturas de Proveedores y Abonos..."

super_repuestos = created_suppliers.find { |s| s.name == "Super Repuestos" }
impresa         = created_suppliers.find { |s| s.name == "Impresa Repuestos" }
disagro         = created_suppliers.find { |s| s.name == "Disagro Repuestos" }
el_globo        = created_suppliers.find { |s| s.name == "Autopartes El Globo" }
san_jose        = created_suppliers.find { |s| s.name == "Lubricantes y Filtros San José" }

# ----------------------------------------------------------------------
# FACTURAS PARA SUPER REPUESTOS
# ----------------------------------------------------------------------
inv1 = SupplierInvoice.new(
  supplier: super_repuestos,
  invoice_number: "FAC-10293",
  voucher_number: "CCF-88120",
  voucher_type: "ccf",
  description: "Compra de pastillas de freno, amortiguadores y discos delanteros",
  issue_date: 45.days.ago.to_date,
  due_date: 15.days.ago.to_date,
  total_amount: 1450.00
)
inv1.supplier_payments.build(
  payment_date: 20.days.ago.to_date,
  amount: 450.00,
  payment_method: "transferencia",
  reference_number: "TRX-48201",
  notes: "Primer abono a la factura"
)
inv1.save!

SupplierInvoice.create!(
  supplier: super_repuestos,
  invoice_number: "FAC-10450",
  voucher_number: "CCF-88345",
  voucher_type: "ccf",
  description: "Kits de distribución, fajas de motor y bombas de agua",
  issue_date: 10.days.ago.to_date,
  due_date: 20.days.from_now.to_date,
  total_amount: 820.50
)

# ----------------------------------------------------------------------
# FACTURAS PARA IMPRESA REPUESTOS
# ----------------------------------------------------------------------
inv3 = SupplierInvoice.new(
  supplier: impresa,
  invoice_number: "IMP-7741",
  voucher_number: "CCF-4410",
  voucher_type: "ccf",
  description: "Lote de sensores ABS, bujías de iridio y bobinas de encendido",
  issue_date: 60.days.ago.to_date,
  due_date: 15.days.ago.to_date,
  total_amount: 2100.00
)
inv3.supplier_payments.build(
  payment_date: 30.days.ago.to_date,
  amount: 1000.00,
  payment_method: "transferencia",
  reference_number: "TRX-9912",
  notes: "Abono 50%"
)
inv3.supplier_payments.build(
  payment_date: 10.days.ago.to_date,
  amount: 1100.00,
  payment_method: "cheque",
  reference_number: "CHQ-00129",
  notes: "Pago del saldo restante"
)
inv3.save!

SupplierInvoice.create!(
  supplier: impresa,
  invoice_number: "IMP-8102",
  voucher_number: "CCF-4589",
  voucher_type: "ccf",
  description: "Faros LED, vías direccionales y silvines universales",
  issue_date: 50.days.ago.to_date,
  due_date: 5.days.ago.to_date,
  total_amount: 675.25
)

# ----------------------------------------------------------------------
# FACTURAS PARA DISAGRO REPUESTOS
# ----------------------------------------------------------------------
SupplierInvoice.create!(
  supplier: disagro,
  invoice_number: "DIS-00381",
  voucher_number: "CCF-1029",
  voucher_type: "ccf",
  description: "Filtros de aire agrícola, fajas industriales y rodamientos",
  issue_date: 5.days.ago.to_date,
  due_date: 10.days.from_now.to_date,
  total_amount: 1250.00
)

# ----------------------------------------------------------------------
# FACTURAS PARA AUTOPARTES EL GLOBO
# ----------------------------------------------------------------------
inv6 = SupplierInvoice.new(
  supplier: el_globo,
  invoice_number: "GLO-9011",
  voucher_number: "CCF-6712",
  voucher_type: "ccf",
  description: "Radiadores, termostatos y mangueras de alta presión",
  issue_date: 15.days.ago.to_date,
  due_date: 15.days.from_now.to_date,
  total_amount: 1800.00
)
inv6.supplier_payments.build(
  payment_date: 5.days.ago.to_date,
  amount: 800.00,
  payment_method: "efectivo",
  reference_number: "REC-041",
  notes: "Anticipo entregado al vendedor"
)
inv6.save!

# ----------------------------------------------------------------------
# FACTURAS PARA LUBRICANTES Y FILTROS SAN JOSÉ
# ----------------------------------------------------------------------
inv7 = SupplierInvoice.new(
  supplier: san_jose,
  invoice_number: "LSJ-5510",
  voucher_number: "CCF-3390",
  voucher_type: "ccf",
  description: "Tambores de aceite 20W50, 10W30 y galones de refrigerante",
  issue_date: 25.days.ago.to_date,
  due_date: 35.days.from_now.to_date,
  total_amount: 3200.00
)
inv7.supplier_payments.build(
  payment_date: 20.days.ago.to_date,
  amount: 3200.00,
  payment_method: "transferencia",
  reference_number: "TRX-77102",
  notes: "Pago total con descuento por pronto pago"
)
inv7.save!

SupplierInvoice.create!(
  supplier: san_jose,
  invoice_number: "LSJ-5680",
  voucher_number: "CCF-3450",
  voucher_type: "ccf",
  description: "Filtros de aceite, filtros de combustible diésel y grasa industrial",
  issue_date: 2.days.ago.to_date,
  due_date: 58.days.from_now.to_date,
  total_amount: 940.00
)

puts "=========================================="
puts " ¡Seeds cargados exitosamente!"
puts " 5 Proveedores creados."
puts " 8 Facturas creadas con sus saldos y estados."
puts "=========================================="