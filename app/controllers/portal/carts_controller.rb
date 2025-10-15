class Portal::CartsController < ApplicationController
  #before_action :ensure_cliente!
   layout "dashboard", only: [:checkout]
    before_action :set_current_user
  def show
    session[:cart] ||= []
    @cart = session[:cart]
    
     respond_to do |format|
    format.html { render partial: "portal/carts/cart", locals: { cart: @cart } }
    format.json { render json: @cart }
     end
  end

  def add
    session[:cart] ||= []
    product_id = params[:id]
    quantity = params[:quantity].to_i

    product = Product.find_by(id: product_id)
    unless product
      render json: { success: false, error: "Producto no encontrado" } and return
    end

    item = session[:cart].find { |i| i["product_id"] == product.id.to_s }
    if item
      item["quantity"] += quantity
    else
      session[:cart] << { "product_id" => product.id.to_s, "quantity" => quantity }
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.html { render partial: "portal/carts/cart", locals: { cart: session[:cart] } }
    end
  end

  def increase
    session[:cart] ||= []
    item = session[:cart].find { |i| i["product_id"] == params[:id] }
    item["quantity"] += 1 if item

    render partial: "portal/carts/cart", locals: { cart: session[:cart] }
  end

  def decrease
    session[:cart] ||= []
    item = session[:cart].find { |i| i["product_id"] == params[:id] }
    if item
      item["quantity"] -= 1
      session[:cart].delete(item) if item["quantity"] <= 0
    end

    render partial: "portal/carts/cart", locals: { cart: session[:cart] }
  end

  def remove
    session[:cart] ||= []
    session[:cart].reject! { |i| i["product_id"] == params[:id] }

    render partial: "portal/carts/cart", locals: { cart: session[:cart] }
  end

  def checkout
    session[:cart] ||= []
    @cart = session[:cart]
    
    
    @cart_items = @cart.map do |item|
      product = Product.find(item["product_id"])
      {
        product: product,
        quantity: item["quantity"],
        subtotal: product.price * item["quantity"]
      }
    end

    @subtotal = @cart_items.sum { |item| item[:subtotal] }
    @total = @subtotal #Aquí se puede agregar e metodo de descuento

    render layout: "dashboard"
  end

  def create_purchase
  session[:cart] ||= []
  @cart = session[:cart]
  return redirect_to portal_home_path, alert: "Tu carrito está vacío" if @cart.empty?

  # Buscar el usuario que será el "cajero en línea"
  cajero_en_linea_usuario = User.find_by(full_name: "Cajero en Linea")
  # Buscar el cajero asociado a ese usuario
  cajero_en_linea = Cajero.find_by(user: cajero_en_linea_usuario)
  # Buscar la caja asociada a ese cajero
  caja_en_linea = cajero_en_linea.caja if cajero_en_linea.present?

  unless cajero_en_linea && caja_en_linea
    return redirect_to portal_cart_path, alert: "No se pudo asignar cajero o caja."
  end

  # Calcular totales del carrito
  @cart_items = @cart.map do |item|
    product = Product.find(item["product_id"])
    {
      product: product,
      quantity: item["quantity"].to_i,
      subtotal: product.price * item["quantity"].to_i
    }
  end

  subtotal = @cart_items.sum { |i| i[:subtotal] }
  total = subtotal #Aquí se puede agregar el descuento cuando se implemente

  # Crear la venta asociando cajero y caja
  sale = Sale.new(
    sold_at: Time.now,
    client_name: @current_user.full_name,
    client_id: @current_user.id,
    cajero: cajero_en_linea,
    caja: caja_en_linea,
    total_amount: total,
    status: "pendiente"
  )

  # Asociar productos
  @cart_items.each do |item|
    sale.product_sales.build(
      product_id: item[:product].id,
      quantity: item[:quantity],
      price: item[:product].price,
      subtotal: item[:subtotal]
    )
  end

  # Guardar venta
  if sale.save
    # Asociar la venta al usuario mediante UserSale
    UserSale.create!(
      sale: sale,
      user: @current_user,
      sale_date: Time.now
    )

    # Limpiar carrito
    session[:cart] = []
    redirect_to portal_purchases_path, notice: "¡Compra realizada con éxito!"
  else
    logger.error sale.errors.full_messages
    redirect_to portal_cart_path, alert: "No se pudo completar la compra."
  end
end


  private

  def ensure_cliente!
    # Solo permite continuar si el usuario es cliente
    if current_user.nil? || current_user.role != "cliente"
      render json: { success: false, error: "Solo los clientes pueden usar el carrito." }, status: :forbidden
    end
  end

  
  
  def set_current_user
  @current_user = User.find_by(id: session[:user_id])
end
end
