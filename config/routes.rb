Rails.application.routes.draw do
  # Namespace para Portal
  namespace :portal do
    get "/login", to: "authentication#login"
    post "/new_login", to: "authentication#new_login"
    get "/signup", to: "authentication#signup"
    post "/signup", to: "authentication#user_request"
    get "/validating_user", to: "authentication#validating_user"
    post "/signup_create", to: "authentication#signup_create"
    put "/logout", to: "authentication#logout"

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
    resource :profile, only: [:show, :update]
    resources :addresses, only: [:show,:update,:destroy]
      
    # Carrito y compras
    resource :cart, only: [:show] do
      post 'add/:id', to: 'carts#add', as: 'add'
      post 'increase/:id', to: 'carts#increase', as: 'increase'
      post 'decrease/:id', to: 'carts#decrease', as: 'decrease'
      delete 'remove/:id', to: 'carts#remove', as: 'remove'
      post 'apply_discount_code', to: 'carts#apply_discount_code', as: 'apply_discount_code'
    end

    # Checkout
    get "checkout", to: "carts#checkout", as: 'checkout'
    post "checkout", to: "carts#create_purchase", as: 'create_purchase'

    # Compras
    resources :purchases, only: [:index, :show] do
      get "schedule_appointment", to: "purchases#schedule_appointment"
      post "confirm_appointment", to: "purchases#confirm_appointment"
      get "estado_entrega", to: "purchases#delivery_status_real_time"
      get "refresh_delivery_status", to: "purchases#refresh_delivery_status"
    end

    root "landing#index"
  end

  # Namespace para Admin
  namespace :admin do
    resources :users, only: [:index, :edit, :destroy, :new]
    post "/users/create", to: "users#create"
    patch "/users/update", to: "users#update"
    get "/users/edit_password", to: "users#edit_password"
    patch "/users/:id/update_password", to: "users#update_password", as: "user_update_password"


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

    resources :empleados do
      resources :asistencias, only: [:index] do
        collection do
          post :actualizar_semana
        end
      end
    end

    # # config/routes.rb dentro de namespace :admin
    # resources :asistencias, only: [:index] do
    #   collection do
    #     get :reporte_cortes
    #     post :registrar
    #     post :procesar_corte
    #   end
    # end

    resources :planillas do
      member do
        post :procesar # Botón para disparar planilla.generar_planilla!
      end
      resources :boletas_de_pago, only: [:show]
    end

    # Ruta para ajustar parámetros de ley desde UI
    resource :configuracion_planilla, only: [:edit, :update, :show]

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

    resources :roles, except: [:show]

    # 🔹 Reportes
    # 🔹 Reportes
    get 'reports', to: 'reports#index', as: :admin_reports
    get 'reports/top_products', to: 'reports#top_products', as: :top_products_admin_reports
    get 'reports/top_brands', to: 'reports#top_brands', as: :top_brands_admin_reports
    get 'reports/best_seller', to: 'reports#best_seller', as: :best_seller_admin_reports
    get 'reports/seller_details', to: 'reports#seller_details', as: :seller_details_admin_reports

   # 🔹 Configuraciones del sitio
  get "configuraciones", to: "site_configurations#show", as: :site_configuration
  patch "configuraciones/update", to: "site_configurations#update", as: :update_site_configuration
  post "configuraciones/mass_mail", to: "site_configurations#mass_mail", as: :mass_mail
  #get "configuraciones/not", to: "site_configurations#not", as: :site_notifications_alerts  
  
  end

  # Health check y landing
  get "up", to: "rails/health#show", as: :rails_health_check
  get 'landing/index', to: 'landing#index', as: 'landing_index'
  
  # Cambiamos la ruta raíz para que haga un redirect permanente/temporal al login de admin
  root to: redirect('/admin/login')
end
