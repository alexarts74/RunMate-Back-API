Rails.application.routes.draw do
  namespace :api do
    get 'messages/index'
    get 'messages/show'
    get 'messages/update'
    get 'messages/create'
    get 'users/show'
    get 'users/update'
  end
    devise_for :users, controllers: {
      sessions: 'api/sessions',
      registrations: 'api/registrations'
    }

    namespace :api do
      devise_scope :user do
        # Authentification
        post 'users/log_in', to: 'sessions#create'
        delete 'users/log_out', to: 'sessions#destroy'

        # Gestion du compte
        post 'users/sign_up', to: 'registrations#create'
        delete 'users/sign_out', to: 'registrations#destroy'  # Suppression du compte via Devise

        # Profil utilisateur
        get 'users/profile', to: 'users#show'
        put 'users/profile', to: 'users#update'
        get 'users/current', to: 'users#current'
      end

      # Autres ressources API
      resources :messages, only: [:index, :show, :update, :destroy, :create]
      resources :users, only: [:index, :show, :update, :destroy]
      resources :runner_profiles, only: [:create, :update]
      resources :matches, only: [:index] do
        collection do
          post 'apply_filters'
        end
      end
    end
end
