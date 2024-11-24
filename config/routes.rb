Rails.application.routes.draw do
    devise_for :users, controllers: {
      sessions: 'api/sessions',
      registrations: 'api/registrations'
    }

    namespace :api do
      devise_scope :user do
        # Connexion
        post 'users/log_in', to: 'sessions#create'
        # Déconnexion
        delete 'users/log_out', to: 'sessions#destroy'
        # Inscription
        post 'users/sign_up', to: 'registrations#create'
        # Suppression de compte
        delete 'users/sign_out', to: 'registrations#destroy'
      end

      # Autres ressources API
      resources :messages, only: [:index, :show, :update, :destroy]
      resources :users, only: [:index, :show, :update, :destroy]
      resource :runner_profile, only: [:create, :update]
      resources :matches, only: [:index]
    end
end
