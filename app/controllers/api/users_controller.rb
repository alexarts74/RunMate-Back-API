class Api::UsersController < ApplicationController
  before_action :authenticate_user_from_token!

  def show
    render json: {
      user: current_user.as_json(
        only: [:id, :email, :name, :last_name, :age, :gender, :location, :bio, :profile_image],
        include: {
          runner_profile: {
            only: [:actual_pace, :usual_distance, :availability, :objective]
          }
        }
      )
    }
  end

  def update
    if current_user.update(user_params)
      if params[:user][:runner_profile].present? && current_user.runner_profile.present?
        current_user.runner_profile.update(runner_profile_params)
      end

      render json: {
        message: "Profil mis à jour avec succès",
        user: current_user.as_json(
          only: [:id, :email, :name, :last_name, :age, :gender, :location, :bio, :profile_image],
          include: {
            runner_profile: {
              only: [:actual_pace, :usual_distance, :availability, :objective]
            }
          }
        )
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email,
      :name,
      :last_name,
      :age,
      :gender,
      :location,
      :bio,
      :profile_image
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
