Rails.application.routes.draw do
  # Configuration de Devise
  devise_for :users, controllers: {
    sessions: 'api/sessions',
    registrations: 'api/registrations'
  }

  # Toutes les routes API
  namespace :api do
    devise_scope :user do
      # Authentification
      post 'users/log_in', to: 'sessions#create'
      delete 'users/log_out', to: 'sessions#destroy'

      # Gestion du compte
      post 'users/sign_up', to: 'registrations#create'
      delete 'users/sign_out', to: 'registrations#destroy'

      # Profil utilisateur
      get 'users/profile', to: 'users#show'
      put 'users/profile', to: 'users#update'
      get 'users/current', to: 'users#current'
      put 'users/update_push_token', to: 'users#update_push_token'
    end

    # Resources standards
    resources :messages, only: [:index, :show, :update, :create, :destroy]
    resources :users, only: [:index, :show, :update, :destroy]
    resources :runner_profiles, only: [:create, :update]

    resources :matches, only: [:index] do
      collection do
        post 'apply_filters'
      end
    end

    resources :notifications, only: [:index] do
      member do
        put :mark_as_read
      end
      collection do
        put :mark_all_as_read
        get :test
        post :test
      end
    end

    # Routes pour les groupes privés
    resources :running_groups do
      member do
        post :request_to_join
        post :accept_request
        delete :decline_request
        get :pending_requests
      end
      collection do
        get :search_users
      end
    end

    # Routes pour les events publics
    resources :events do
      member do
        post :join
        delete :leave
      end
      collection do
        get :upcoming
        get :my_events
      end
    end
  end
end
