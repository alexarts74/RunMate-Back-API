class Api::RunnerProfilesController < ApplicationController
  before_action :authenticate_user_from_token!

  def create
    profile = current_user.build_runner_profile(runner_profile_params)
    if profile.save
      render json: {
        message: "Profil coureur créé avec succès",
        profile: profile
      }
    else
      Rails.logger.error "Erreurs de validation : #{profile.errors.full_messages}"
      render json: {
        errors: profile.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    profile = current_user.runner_profile
    if profile.update(runner_profile_params)
      render json: {
        message: "Profil coureur mis à jour avec succès",
        profile: profile
      }
    else
      render json: {
        errors: profile.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def runner_profile_params
    params.require(:runner_profile).permit(
      :actual_pace,
      :usual_distance,
      :objective,
      availability: []
    )
  end
end
