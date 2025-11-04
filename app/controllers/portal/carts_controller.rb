class Portal::CartsController < ApplicationController
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
      session[:cart] << { "product_id" => product.id.to_s, "quantity" => quantity, "unit_price" => product.price }
    end

    render json: { success: true }
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
      quantity = item["quantity"].to_i
      discounted_price = item["discounted_price"] || product.price
      subtotal = discounted_price * quantity

      {
        product: product,
        quantity: quantity,
        unit_price: discounted_price,
        subtotal: subtotal,
        discount: product.discount
      }
    end

    @subtotal = @cart_items.sum { |i| i[:subtotal] }
    @total = @subtotal
    render layout: "dashboard"
  end

  # 🔹 Acción corregida para aplicar cupones con validación de producto
  def apply_discount_code
    session[:cart] ||= []

    # Leer datos JSON desde fetch
    data = JSON.parse(request.body.read)
    product_id = data["product_id"].to_s
    code_value = data["code"].strip.upcase

    discount_code = DiscountCode.find_by(value: code_value)
    return render json: { success: false, error: "Código no válido" } unless discount_code

    # 🔹 Validación: el cupón solo aplica al producto asignado
    if discount_code.product_id.to_s != product_id
      return render json: { success: false, error: "El cupón no es válido para este producto" }
    end

    # Verificar si el usuario ya lo usó
    if UserDiscountCode.where(user_id: @current_user.id, discount_code_id: discount_code.id).exists?
      return render json: { success: false, error: "Ya usaste este código" }
    end

    applied = false
    new_price = nil

    # Actualizar precio en la sesión
    session[:cart].each do |item|
      if item["product_id"] == product_id
        item["coupon_code"] = discount_code.value
        item["discounted_price"] = (item["unit_price"].to_f * (1 - discount_code.discount / 100.0)).round(2)
        new_price = item["discounted_price"]
        applied = true
        break
      end
    end

    if applied
      render json: { success: true, discount: discount_code.discount, product_name: Product.find(product_id).name, new_price: new_price }
    else
      render json: { success: false, error: "Producto no encontrado en el carrito" }
    end
  end

  def create_purchase
    # binding.pry7
    session[:cart] ||= []
    return redirect_to portal_home_path, alert: "Tu carrito está vacío" if session[:cart].empty?

    @cart_items = session[:cart].map do |item|
      product = Product.find(item["product_id"])
      quantity = item["quantity"].to_i
      discounted_price = item["discounted_price"] || product.price
      subtotal = discounted_price * quantity

      # Registrar uso del código
      if item["coupon_code"].present?
        discount_code = DiscountCode.find_by(value: item["coupon_code"])
        UserDiscountCode.create!(user_id: @current_user.id, discount_code_id: discount_code.id) if discount_code
      end

      {
        product: product,
        quantity: quantity,
        unit_price: discounted_price,
        subtotal: subtotal,
        coupon_code: item["coupon_code"]
      }
    end

    total = @cart_items.sum { |i| i[:subtotal] }

    sale = Sale.new(
      sold_at: Time.now,
      client_name: @current_user.full_name,
      client_id: @current_user.id,
      total_amount: total,
      status: "pendiente",
      cajero_id: Cajero.where(nombre: "Cajero en Linea").first.id,
      caja_id: Caja.where(nombre: "Caja en linea").first.id
    )

    @cart_items.each do |item|
      sale.product_sales.build(
        product_id: item[:product].id,
        quantity: item[:quantity],
        unit_price: item[:unit_price],
        discount: item[:product].discount || 0,
        subtotal: item[:subtotal]
      )
    end

    if sale.save
      session[:cart] = []
      redirect_to portal_purchases_path, notice: "¡Compra realizada con éxito!"
    else
      redirect_to portal_cart_path, alert: "No se pudo completar la compra."
    end
  end

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end
end
