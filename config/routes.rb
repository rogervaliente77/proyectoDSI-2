Rails.application.routes.draw do
  # Namespace para Portal
  namespace :portal do
    #authentication
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"
    
    #home
    get "/home", to: "home#index"

    #charlas
    get "/charlas", to: "conferences#index"
    get "/mis_charlas", to: "conferences#my_registrations"
    get "/charlas/new", to: "conferences#new"
    post "/charlas/create", to: "conferences#create"

    #charla registration
    post "/charlas/registration/:conference_id", to: "conferences#new_conference_registration"

    #productos
    get "/productos", to: "products#index"
    get "/mis_productos", to: "products#my_products"
    post "/productos/canjear/:product_id", to: "products#canjear_producto", as: :canjear_producto
  end

  # Namespace para Admin
  namespace :admin do
    # Ejemplo de rutas para un módulo Admin
    resources :users, only: [:index, :show, :edit, :update, :destroy]
    get "/charlas", to: "conferences#index"
    get "/charlas/new", to: "conferences#new"
    post "/charlas/create", to: "conferences#create"

    #document
    get "/documentos", to: "documents#index"
    get "/documentos/new", to: "documents#new"
    get "/documentos/show", to: "documents#show"
    post "/documentos/create", to: "documents#create"
    get "/documentos/edit", to: "documents#edit"
    put "/documentos/update", to: "documents#update"

    #products
    get "/productos", to: "products#index"
    get "/productos/new", to: "products#new"
    post "/productos/create", to: "products#create"
    get "/productos/:product_id/canjes", to: "products#product_sales", as: :product_sales
    get "/productos/:product_id/edit", to: "products#edit", as: :edit_product
    put "/productos/update", to: "products#update"
    delete "productos/destroy", to: "products#destroy", as: :destroy_product
    patch "/productos/mark_as_delivered", to: "products#mark_as_delivered"


    #authentication
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"

    #home
    get "/home", to: "home#index"

  end


  # Ruta para pruebas (puedes eliminar o mover esto a un namespace si es necesario)
  resources :pruebas

  # Ruta para ver el estado de salud de la aplicación
  get "up", to: "rails/health#show", as: :rails_health_check

  # Define la ruta raíz de la aplicación
  root "portal/authentication#login" # Ajusta esto si tu página principal es el login del portal
end
