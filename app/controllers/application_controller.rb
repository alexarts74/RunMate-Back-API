require "application_responder"
class ApplicationController < ActionController::API
  self.responder = ApplicationResponder
  respond_to :json

  before_action :log_application_info
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def log_application_info
    Rails.logger.info "Controller: #{params[:controller]}, Action: #{params[:action]}"
  end

  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last

    if token.blank?
      return render json: { error: "Token requis" }, status: :unauthorized
    end

    user = User.find_by(authentication_token: token)

    if user
      sign_in user, store: false
    else
      render json: { error: "Token non valide" }, status: :unauthorized
    end
  end

  def configure_permitted_parameters
    if params[:user].present?
      devise_parameter_sanitizer.permit(:sign_up, keys: [
        :name,
        :last_name,
        :bio,
        :age,
        :profile_image,
        :level,
        :gender,
        :location
      ])

      devise_parameter_sanitizer.permit(:account_update, keys: [
        :name,
        :last_name,
        :bio,
        :age,
        :profile_image,
        :level,
        :gender,
        :location
      ])
    end
  end
end
