class Api::UsersController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_user, only: [:show, :update]
  # On peut enlever set_user car on utilise directement current_user

  def show
    render json: user_with_profile_json
  end

  def update
    if @user.update(user_params)
      if params[:user][:runner_profile].present?
        @runner_profile = @user.runner_profile || @user.build_runner_profile
        @runner_profile.update(runner_profile_params)
      end
      render json: @user
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def current
    if current_user
      render json: current_user, include: :runner_profile
    else
      render json: { error: "Utilisateur non authentifié" }, status: :unauthorized
    end
  end

  # app/controllers/api/users_controller.rb
def update_push_token
  Rails.logger.info "🔄 Début mise à jour token Expo"

  # Vérifier l'état initial
  Rails.logger.info "État initial:"
  Rails.logger.info "- ID: #{current_user.id}"
  Rails.logger.info "- Email: #{current_user.email}"
  Rails.logger.info "- Token en DB: #{ActiveRecord::Base.connection.execute("SELECT expo_push_token FROM users WHERE id = #{current_user.id}").first['expo_push_token']}"

  # Extraire le token
  token = params[:expo_push_token].presence || params.dig(:user, :expo_push_token)
  Rails.logger.info "Token reçu: #{token}"

  unless token
    render json: { error: "Token non fourni" }, status: :bad_request
    return
  end

  begin
    # Mise à jour
    success = current_user.update_column(:expo_push_token, token)
    current_user.reload

    # Vérifier directement en base
    token_in_db = ActiveRecord::Base.connection.execute(
      "SELECT expo_push_token FROM users WHERE id = #{current_user.id}"
    ).first['expo_push_token']

    Rails.logger.info "État après mise à jour:"
    Rails.logger.info "- Token via Active Record: #{current_user.expo_push_token}"
    Rails.logger.info "- Token via SQL direct: #{token_in_db}"

    render json: {
      message: "Token mis à jour avec succès",
      user: {
        id: current_user.id,
        email: current_user.email,
        expo_push_token: token_in_db, # Utiliser la valeur directe de la DB
        expo_push_token_from_model: current_user.expo_push_token # Pour comparaison
      }
    }
  rescue => e
    Rails.logger.error "❌ Exception: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: {
      error: "Erreur serveur",
      details: e.message
    }, status: :internal_server_error
  end
end

  private

  def set_user
    @user = current_user
  end

  def user_with_profile_json
    @user.as_json(
      only: [:id, :email, :first_name, :last_name, :age, :gender, :location, :bio, :profile_image],
      include: {
        runner_profile: {
          only: [:actual_pace, :usual_distance, :availability, :objective]
        }
      }
    )
  end

  def user_params
    params.require(:user).permit(
      :email,
      :first_name,
      :last_name,
      :age,
      :gender,
      :profile_image,
      :bio,
      :expo_push_token,
      :latitude,
      :longitude,
      :city,
      :department,
      :country,
      :postcode
    )
  end

  def runner_profile_params
    params.require(:user).require(:runner_profile).permit(
      :actual_pace,
      :availability,
      :objective,
      :usual_distance
    )
  end
end
