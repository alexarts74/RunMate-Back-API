class Api::UsersController < ApplicationController
  before_action :authenticate_user_from_token!
  # On peut enlever set_user car on utilise directement current_user

  def show
    render json: user_with_profile_json
  end

  def update


    # Désactiver la validation du mot de passe si non fourni
    current_user.skip_password_validation = true if params[:user][:password].blank?
    current_user.skip_password_validation = true if params[:user][:password_confirmation].blank?

    if current_user.update(user_params)
      # Mise à jour du profil runner si présent
      if params[:user][:runner_profile].present? && current_user.runner_profile.present?
        current_user.runner_profile.update(runner_profile_params)
      end

      render json: {
        message: "Profil mis à jour avec succès",
        user: user_with_profile_json
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def current
    if current_user
      render json: current_user, include: :runner_profile
    else
      render json: { error: "Utilisateur non authentifié" }, status: :unauthorized
    end
  end

  def update_push_token
    current_user.skip_password_validation = true if params[:user][:password].blank?
    current_user.skip_password_validation = true if params[:user][:password_confirmation].blank?
    if current_user.update(expo_push_token: params[:expo_push_token])
      render json: {
        message: "Token mis à jour avec succès",
        user: current_user.as_json(only: [:id, :expo_push_token])
      }
    else
      render json: {
        error: "Erreur lors de la mise à jour du token"
      }, status: :unprocessable_entity
    end
  end

  private

  def user_with_profile_json
    current_user.as_json(
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
      :location,
      :bio,
      :profile_image,
      :expo_push_token
    )
  end

  def runner_profile_params
    params.require(:user).require(:runner_profile).permit(
      :actual_pace,
      :usual_distance,
      :availability,
      :objective
    )
  end
end
