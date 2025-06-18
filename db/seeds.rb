# db/seeds.rb
require 'bcrypt'

puts "Creando usuarios"

User.create!(
  first_name: "Super",
  last_name: "Admin",
  email: "super_admin@ferrepro.com",
  is_valid: true,
  is_admin: false,
  role: "super_admin",
  password: "123123",
  password_confirmation: "123123"
)

User.create!(
  first_name: "Admin",
  last_name: "Ferrepro",
  email: "admin@ferrepro.com",
  is_valid: true,
  is_admin: false,
  role: "admin",
  password: "123123",
  password_confirmation: "123123"
)

User.create!(
  first_name: "Julio Enrique",
  last_name: "Martinez Hernandez",
  email: "cajero1@ferrepro.com",
  is_valid: true,
  is_admin: false,
  role: "cajero",
  password: "123123",
  password_confirmation: "123123"
)

puts "Creando categorias"
Category.create!(
    name: "Electricidad",
    description: "Herramientas y productos electricos"
)

Category.create!(
    name: "Fontaneria",
    description: "Herramientas y productos de fontaneria"
)

puts "Creando productos"
Product.create!(
    name: "Tenaza trupper",
    description: "Tenaza para cortar conductor",
    quantity: 50,
    price: 8.50,
    image_url: "https://sv.epaenlinea.com/media/catalog/product/cache/e28d833c75ef32af78ed2f15967ef6e0/e/5/e596d954-3cb3-4f6a-8f1d-8c04cd08cb85.jpg",
    category_id: 1
)

Product.create!(
    name: "Tester digital trupper",
    description: "Multimetro digital, para medir voltaje, intensidad y resistencia AC/DC",
    quantity: 30,
    price: 12.75,
    image_url: "https://sv.epaenlinea.com/media/catalog/product/cache/e28d833c75ef32af78ed2f15967ef6e0/e/2/e2a8c455-3416-497f-a1f7-50048b13d826.jpg",
    category_id: 1
)

Product.create!(
    name: "Foco led 40 watts",
    description: "Marca phillips, potencia 40 watts",
    quantity: 50,
    price: 7.25,
    image_url: "https://www.freundferreteria.com/Productos/GetMultimedia?idProducto=622c6b69-f4d3-41e4-8d65-97546d2c4ba5&idMultimediaProducto=e076c884-c165-40ae-8d4c-11bfdcbd3685&width=500&height=500&qa=90&esImagen=True&ext=.jpg",
    category_id: 1
)

Product.create!(
  name: "Juego de destornilladores aislados 7 pzs 1000 V",
  description: "Set de 7 destornilladores aislados, cubiertos contra 1000 V, incluye puntas planas y Philips; ideal para instalaciones eléctricas.",
  quantity: 30,
  price: 39.99,
  image_url: "https://globaltoolsgt.com/cdn/shop/files/STMT60175-LA-juego-de-desarmadores-aislados-stanley_1_1024x.jpg?v=1697936621", 
  category_id: 1
)

Product.create!(
  name: "Set destornilladores aislados Milwaukee 7 pzs",
  description: "Destornilladores de punta fina aislados 1000 V de la marca Milwaukee, ideales para trabajos en espacios reducidos.",
  quantity: 25,
  price: 53.97,
  image_url: "https://www.milwaukeetool.com/--/web-images/sc/f1a8d9649fdd47568181f3043fdb48aa?hash=7c1ed61a85a5692d75e138da79f4758f&lang=en", 
  category_id: 1
)

Product.create!(
  name: "Set destornilladores aislados Klein 6 pzs 1000 V",
  description: "Set de 6 destornilladores aislados 1000 V Klein Tools, con puntas Slotted, Phillips y Square; mango ergonómico y seguro.",
  quantity: 20,
  price: 39.97,
  image_url: "https://media.kleintools.io/images/original/klein/85076ins_mb.jpg", 
  category_id: 1
)

Product.create!(
    name: "Lavamanos",
    description: "Lavamanos de porcelana blanco",
    quantity: 10,
    price: 75.00,
    image_url: "https://sv.epaenlinea.com/media/catalog/product/cache/e28d833c75ef32af78ed2f15967ef6e0/3/5/35d47ed9-4d02-4ffd-90d3-ebca9e35990e.jpg",
    category_id: 2
)

Product.create!(
    name: "Grifo lavamanos monomando cuello bajo cromado pomo",
    description: "Su diseño monomando de agua fría, con cuerpo, cartucho y manija de plástico, ofrece una solución práctica y moderna. Disfrute de un flujo de agua preciso y constante, ideal para lavamanos y espacios donde se requiere agua fría.",
    quantity: 20,
    price: 15.00,
    image_url: "https://sv.epaenlinea.com/media/catalog/product/cache/e28d833c75ef32af78ed2f15967ef6e0/3/5/3599a2d7-27fe-487a-bda2-a18d7b8cda52.jpg",
    category_id: 2
)

Product.create!(
  name: "Válvula check PVC 3/4\" anti-retorno",
  description: "Válvula check de PVC CED‑40 de 3/4\" para evitar retorno de agua en drenajes.",
  quantity: 40,
  price: 3.00,
  image_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTs4l4beK5GB_84cZ59iEwILmDItAdHket2iA&s",
  category_id: 2
)

Product.create!(
  name: "Válvula esfera PVC 3/4\"",
  description: "Válvula de esfera en PVC CED‑40 de 3/4\" con palanca de metal ideal para sistemas hidráulicos.",
  quantity: 25,
  price: 5.50,
  image_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5leO4_JtfFwC6a3lRwbphF8np59dxUSwiIg&s",
  category_id: 2
)

Product.create!(
  name: "Válvula de drenaje 3/4\" PVC",
  description: "Válvula especial de drenaje en PVC 3/4\" para sistemas sanitarios, con rosca y tapa superior.",
  quantity: 30,
  price: 4.75,
  image_url: "https://m.media-amazon.com/images/I/61JwvJv2V4L._AC_UF894,1000_QL80_.jpg",
  category_id: 2
)

puts "Creando cajas y cajeros"
Caja.create!(
    nombre: "Caja 1",
    caja_number: 1
)

Caja.create!(
    nombre: "Caja 2",
    caja_number: 2
)

Cajero.create!(
    nombre: "Cajero 1",
    caja_id: 1,
    user_id: 3
)
