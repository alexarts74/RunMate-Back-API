class Api::SessionsController < Devise::SessionsController
    skip_before_action :verify_signed_out_user, only: [:destroy]
    before_action :authenticate_user_from_token!, only: [:destroy]

    def create
        self.resource = warden.authenticate!(auth_options)
        sign_in(resource_name, resource)
        token = resource.ensure_authentication_token


        render json: { message: 'Connexion réussie !', user: resource, authentication_token: token}
    end


    def destroy
        if current_user
          current_user.update(authentication_token: nil)
          sign_out current_user
          render json: { message: "Déconnexion réussie" }, status: :ok
        else
          render json: { error: "Aucun utilisateur connecté" }, status: :unauthorized
        end
    end

    private

    def authenticate_user_from_token!
        raw_token = request.headers['Authorization']

        token = raw_token&.split(' ')&.last

        # Vérifier si le token existe dans la base
        user_with_token = User.where.not(authentication_token: nil).pluck(:authentication_token)

        user = token && User.find_by_authentication_token(token)

        if user
          sign_in user, store: false
        else
          render json: { error: 'Token invalide ou expiré' }, status: :unauthorized
        end
    end
end
