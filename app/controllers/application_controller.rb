require "application_responder"

class ApplicationController < ActionController::API
  self.responder = ApplicationResponder
  respond_to :json

  before_action :log_application_info
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def log_application_info
    puts "Requête reçue dans ApplicationController"
    puts "Contrôleur : #{params[:controller]}"
    puts "Action : #{params[:action]}"
  end

  def authenticate_user_from_token!
    puts "Début authentification par token"
    token = request.headers['Authorization']&.split(' ')&.last
    puts "Token reçu: #{token}"

    if token.blank?
      puts "Aucun token fourni"
      return render json: { error: "Token requis" }, status: :unauthorized
    end

    user = User.find_by(authentication_token: token)
    puts "Utilisateur trouvé: #{user&.email}"

    if user
      sign_in user, store: false
      puts "Utilisateur connecté avec succès"
    else
      puts "Token invalide ou utilisateur non trouvé"
      render json: { error: "Token non valide" }, status: :unauthorized
    end
  end

  def configure_permitted_parameters
    if params[:user].present?
      devise_parameter_sanitizer.permit(:sign_up, keys: [
        :name,
        :bio,
        :age,
        :image,
        :level
      ])

      devise_parameter_sanitizer.permit(:account_update, keys: [
        :name,
        :bio,
        :age,
        :image,
        :level
      ])
    end
  end
end
