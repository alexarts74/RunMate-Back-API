class Api::MatchesController < ApplicationController
  before_action :authenticate_user_from_token!

  def index
    @filters = {
      filter_pace: params[:filter_pace] == 'true',
      filter_distance: params[:filter_distance] == 'true',
      filter_availability: params[:filter_availability] == 'true'
    }

    # 1. Base matches (critères fondamentaux)
    base_matches = User.joins(:runner_profile)
                      .where.not(id: current_user.id)
                      .where(location: current_user.location)
                      .where(runner_profiles: {
                        objective: current_user.runner_profile.objective
                      })

    # 2. Application des filtres sélectionnés
    filtered_matches = base_matches.map do |user|
      # Calcul des scores pour chaque critère
      pace_score = pace_compatibility(user)
      distance_score = distance_compatibility(user)
      availability_score = availability_compatibility(user)

      # Vérification des filtres actifs
      matches_pace = !@filters[:filter_pace] || pace_score >= 10
      matches_distance = !@filters[:filter_distance] || distance_score >= 10
      matches_availability = !@filters[:filter_availability] || availability_score >= 10

      # Si l'utilisateur passe tous les filtres actifs
      if matches_pace && matches_distance && matches_availability
        {
          user: user.as_json(only: [:id, :name, :location, :profile_image, :bio],
                            include: {
                              runner_profile: {
                                only: [:actual_pace, :usual_distance, :availability, :objective]
                              }
                            }),
          compatibility_details: {
            pace_match: pace_score,
            distance_match: distance_score,
            availability_match: availability_score
          },
          score: calculate_compatibility_score(user),
          filters_matched: {
            pace: matches_pace,
            distance: matches_distance,
            availability: matches_availability
          }
        }
      end
    end.compact

    render json: {
      matches: filtered_matches,
      total: filtered_matches.size,
      stats: {
        total_base_matches: base_matches.size,
        filtered_matches: filtered_matches.size
      }
    }
  end

  private

  def calculate_compatibility_score(other_user)
    pace_score = pace_compatibility(other_user)
    distance_score = distance_compatibility(other_user)
    availability_score = availability_compatibility(other_user)

    # Pondération des scores
    (pace_score * 0.4 + distance_score * 0.3 + availability_score * 0.3).round
  end

  def pace_compatibility(other_user)
    return 0 unless current_user.runner_profile&.actual_pace.present? &&
                    other_user.runner_profile&.actual_pace.present?

    my_pace = parse_pace(current_user.runner_profile.actual_pace)
    other_pace = parse_pace(other_user.runner_profile.actual_pace)

    diff = (my_pace - other_pace).abs
    case diff
    when 0..30    then 20
    when 31..60   then 15
    when 61..90   then 10
    when 91..120  then 5
    else 0
    end
  end

  def distance_compatibility(other_user)
    return 0 unless current_user.runner_profile&.usual_distance.present? &&
                    other_user.runner_profile&.usual_distance.present?

    my_distance = current_user.runner_profile.usual_distance.to_f
    other_distance = other_user.runner_profile.usual_distance.to_f

    diff = (my_distance - other_distance).abs
    case diff
    when 0..2     then 20
    when 2.1..4   then 15
    when 4.1..6   then 10
    when 6.1..8   then 5
    else 0
    end
  end

  def availability_compatibility(other_user)
    return 0 unless current_user.runner_profile&.availability.present? &&
                    other_user.runner_profile&.availability.present?

    my_availability = JSON.parse(current_user.runner_profile.availability)
    other_availability = JSON.parse(other_user.runner_profile.availability)

    common_days = my_availability & other_availability
    score = (common_days.size.to_f / [my_availability.size, other_availability.size].min) * 20
    score.round
  end

  def parse_pace(pace_string)
    return 0 unless pace_string.present?
    minutes, seconds = pace_string.split(':').map(&:to_i)
    minutes * 60 + seconds
  end
end
