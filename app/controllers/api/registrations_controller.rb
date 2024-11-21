class Api::RegistrationsController < Devise::RegistrationsController
    include ActionController::MimeResponds
    respond_to :json

    skip_before_action :authenticate_scope!, only: [:destroy]
    before_action :authenticate_user_from_token!, only: [:destroy]

    def create
        build_resource(sign_up_params)
        Rails.logger.info "Paramètres reçus : #{params.inspect}"
        Rails.logger.info "Erreurs de validation : #{resource.errors.full_messages}" unless resource.valid?

        if resource.save
            sign_up(resource_name, resource) if resource.active_for_authentication?
            render json: {
              message: 'Inscription réussie',
              user: resource,
              authentication_token: resource.authentication_token
            }, status: :created
        else
            Rails.logger.info "Erreurs de validation : #{resource.errors.full_messages}"
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy
      begin
        current_user.destroy_messages
        current_user.destroy
        render json: { message: "Compte supprimé avec succès" }, status: :ok
      rescue => e
        render json: { error: "Erreur lors de la suppression du compte: #{e.message}" }, status: :unprocessable_entity
      end
    end
    
    private

    def authenticate_user_from_token!
        full_token = request.headers['Authorization']
        token = full_token.gsub('Bearer ', '')
        user = User.find_by(authentication_token: token)
        if user
          sign_in user, store: false
        else
          render json: { error: "Token non valide" }, status: :unauthorized
        end
    end

    def sign_up_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation,
          :name,
          :last_name,
          :bio,
          :age,
          :profile_image,
          :gender,
          :location
        )
    end
end
