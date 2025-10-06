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
    @shipping_cost = 5.00 # ejemplo
    @total = @subtotal + @shipping_cost

    render layout: "dashboard"
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
