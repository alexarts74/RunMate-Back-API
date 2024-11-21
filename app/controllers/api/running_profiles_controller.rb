# class Api::RunningPreferencesController < ApplicationController
#   def create
#     preferences = current_user.build_running_preference(preference_params)
#     if preferences.save
#       render json: { message: "Préférences enregistrées avec succès", preferences: preferences }
#     else
#       render json: { errors: preferences.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   private

#   def preference_params
#     params.require(:running_preference).permit(
#       :preferred_pace_range,
#       :preferred_distance_range,
#       :preferred_availability,
#       :preferred_level,
#       :preferred_gender,
#       age_range: []
#     )
#   end
# end
