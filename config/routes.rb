Rails.application.routes.draw do
  # Namespace para Portal
  namespace :portal do
    # Autenticación y usuarios
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"

    # Home
    get "/home", to: "home#index"

    # Conferencias
    get "/charlas", to: "conferences#index"
    get "/mis_charlas", to: "conferences#my_registrations"
    get "/charlas/new", to: "conferences#new"
    post "/charlas/create", to: "conferences#create"
    post "/charlas/registration/:conference_id", to: "conferences#new_conference_registration"

    # Productos y canjes
    get "/productos", to: "products#index"
    get "/mis_productos", to: "products#my_products"
    post "/productos/canjear/:product_id", to: "products#canjear_producto", as: :canjear_producto

    # Usuarios
    patch "/users/update", to: "users#update"
    get "/users/edit_password", to: "users#edit_password"

    # Carrito y compras
    resource :cart, only: [:show] do
      # Agregar, aumentar, disminuir, eliminar
      post 'add/:id', to: 'carts#add', as: 'add'
      post 'increase/:id', to: 'carts#increase', as: 'increase'
      post 'decrease/:id', to: 'carts#decrease', as: 'decrease'
      delete 'remove/:id', to: 'carts#remove', as: 'remove'

      # Aplicar cupon
      post 'apply_discount_code', to: 'carts#apply_discount_code', as: 'apply_discount_code'
    end

    # Checkout
    get "checkout", to: "carts#checkout", as: 'checkout'
    post "checkout", to: "carts#create_purchase", as: 'create_purchase'

    # Compras
    resources :purchases, only: [:index, :show]

    # Root portal
    root "landing#index"
  end

  # Namespace para Admin
  namespace :admin do
    resources :users, only: [:index, :edit, :destroy, :new]
    post "/users/create", to: "users#create"
    patch "/users/update", to: "users#update"
    get "/users/edit_password", to: "users#edit_password"
    patch "/users/:id/update_password", to: "users#update_password", as: "user_update_password"

    # Conferencias
    get "/charlas", to: "conferences#index"
    get "/charlas/new", to: "conferences#new"
    post "/charlas/create", to: "conferences#create"

    # Categorías
    resources :categories, only: [:index, :new, :create, :edit, :update, :destroy]

    # Home
    get "/home", to: "home#index"

    # Autenticación Admin
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"

    # Documentos
    get "/documentos", to: "documents#index"
    get "/documentos/new", to: "documents#new"
    get "/documentos/show", to: "documents#show"
    post "/documentos/create", to: "documents#create"
    get "/documentos/edit", to: "documents#edit"
    put "/documentos/update", to: "documents#update"

    # Productos
    get "/productos", to: "products#index"
    get "/productos/new", to: "products#new"
    post "/productos/create", to: "products#create"
    get "/productos/:product_id/canjes", to: "products#product_sales", as: :product_sales
    get "/productos/:product_id/edit", to: "products#edit", as: :edit_product
    put "/productos/update", to: "products#update"
    delete "/productos/destroy", to: "products#destroy", as: :destroy_product
    patch "/productos/mark_as_delivered", to: "products#mark_as_delivered"
    get 'products/search', to: 'products#search'

    # Inventario
    get "/productos/inventario", to: "products#inventory", as: :inventory_admin_products
    get "/productos/devueltos", to: "products#devueltos", as: :admin_returned_products

    # Cajas
    get "/cajas", to: "cajas#index"
    get "/cajas/new", to: "cajas#new"
    post "/cajas/create", to: "cajas#create"
    get "/cajas/edit", to: "cajas#edit"
    patch "/cajas/update", to: "cajas#update"

    # Cajeros
    get "/cajeros", to: "cajeros#index"
    get "/cajeros/new", to: "cajeros#new"
    post "/cajeros/create", to: "cajeros#create"
    get "/cajeros/edit", to: "cajeros#edit"
    patch "/cajeros/update", to: "cajeros#update"

    # Ventas
    get "/sales", to: "sales#index"
    get "/sales/new", to: "sales#new"
    post "/sales/create", to: "sales#create"
    get "/sales/detalle_venta", to: "sales#detalle_venta"
    get '/sales/generate_pdf', to: 'sales#generate_pdf', as: :generar_comprobante_venta
    get "/sales/:id/available_products", to: "sales#available_products", as: :sale_available_products
    get '/sales/search_by_code', to: 'sales#search_by_code', as: :search_sale_by_code

    # Devoluciones
    resources :devoluciones, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        patch :autorizar_devolucion
        get :generate_pdf
      end
      collection do
        get :generate_report
      end
    end

    # Marcas y Roles
    resources :marcas, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :roles, except: [:show]

    # Discount Codes
    resources :discount_codes

    # Productos para autocomplete en DiscountCode
    get 'products/search', to: 'products#search'

    # ProductHistory
    resources :product_histories, only: [:index, :show, :destroy], path: "productos/historial"
  end

  # Health check y landing
  get "up", to: "rails/health#show", as: :rails_health_check
  get 'landing/index', to: 'landing#index', as: 'landing_index'
  root "landing#index"
end
