Rails.application.routes.draw do
  # Namespace para Portal
  namespace :portal do
    # authentication
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"
    
    # home
    get "/home", to: "home#index"

    # charlas
    get "/charlas", to: "conferences#index"
    get "/mis_charlas", to: "conferences#my_registrations"
    get "/charlas/new", to: "conferences#new"
    post "/charlas/create", to: "conferences#create"

    # charla registration
    post "/charlas/registration/:conference_id", to: "conferences#new_conference_registration"

    # productos
    get "/productos", to: "products#index"
    get "/mis_productos", to: "products#my_products"
    post "/productos/canjear/:product_id", to: "products#canjear_producto", as: :canjear_producto

    # users
    patch "/users/update", to: "users#update"
    get "/users/edit_password", to: "users#edit_password"
  end

  # Namespace para Admin
  namespace :admin do
    # users
    resources :users, only: [:index, :edit, :destroy, :new] 
    post "/users/create", to: "users#create"
    patch "/users/update", to: "users#update"
    get "/users/edit_password", to: "users#edit_password"
    patch "/users/:id/update_password", to: "users#update_password", as: "user_update_password"

    # charlas
    get "/charlas", to: "conferences#index"
    get "/charlas/new", to: "conferences#new"
    post "/charlas/create", to: "conferences#create"

    # categorias 
    resources :categories, only: [:index, :new, :create, :edit, :update, :destroy]
      
    # home
    get "/home", to: "home#index"

    # authentication
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"

    # documents
    get "/documentos", to: "documents#index"
    get "/documentos/new", to: "documents#new"
    get "/documentos/show", to: "documents#show"
    post "/documentos/create", to: "documents#create"
    get "/documentos/edit", to: "documents#edit"
    put "/documentos/update", to: "documents#update"

    # products
    get "/productos", to: "products#index"
    get "/productos/new", to: "products#new"
    post "/productos/create", to: "products#create"
    get "/productos/:product_id/canjes", to: "products#product_sales", as: :product_sales
    get "/productos/:product_id/edit", to: "products#edit", as: :edit_product
    put "/productos/update", to: "products#update"
    delete "productos/destroy", to: "products#destroy", as: :destroy_product
    patch "/productos/mark_as_delivered", to: "products#mark_as_delivered"
    get 'products/search', to: 'products#search'

    # cajas
    get "/cajas", to: "cajas#index"
    get "/cajas/new", to: "cajas#new"
    post "/cajas/create", to: "cajas#create"
    get "/cajas/edit", to: "cajas#edit"
    patch "/cajas/update", to: "cajas#update"

    # cajeros
    get "/cajeros", to: "cajeros#index"
    get "/cajeros/new", to: "cajeros#new"
    post "/cajeros/create", to: "cajeros#create"
    get "/cajeros/edit", to: "cajeros#edit"
    patch "/cajeros/update", to: "cajeros#update"

    # sales
    get "/sales", to: "sales#index"
    get "/sales/new", to: "sales#new"
    post "/sales/create", to: "sales#create"
    get "/sales/detalle_venta", to: "sales#detalle_venta"
    get '/sales/generate_pdf' => 'sales#generate_pdf', as: :generar_comprobante_venta

    # Rutas para marcas (CRUD completo)
    resources :marcas, except: [:show]

     # get "/marcas", to: "marcas#index", as: :admin_marcas          # Listado de marcas
     # get "/marcas/new", to: "marcas#new", as: :admin_marcas_new   # Crear nueva marca
     # post "/marcas/create", to: "marcas#create", as: :admin_marcas_create  # Guardar nueva marca
     # get "/marcas/:id/edit", to: "marcas#edit", as: :admin_marcas_edit     # Editar marca
     # put "/marcas/:id/update", to: "marcas#update", as: :admin_marcas_update # Actualizar marca
     # delete "/marcas/:id/destroy", to: "marcas#destroy", as: :admin_marcas_destroy # Eliminar marca

  end

  # Rutas extra
  resources :pruebas

  # Health check
  get "up", to: "rails/health#show", as: :rails_health_check

  # 🔹 Ruta nombrada para Landing#index (para filtros)
  get 'landing/index', to: 'landing#index', as: 'landing_index'

  # 🔹 Landing como ruta principal
  root "landing#index"
end
