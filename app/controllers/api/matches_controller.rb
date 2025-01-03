class Api::MatchesController < ApplicationController
  before_action :authenticate_user_from_token!

  def index
    # 1. Base matches avec géolocalisation
    @base_matches = User.includes(:runner_profile)
                        .where.not(id: current_user.id)
                        .where.not(latitude: nil, longitude: nil)
                        .near(
                          [current_user.latitude, current_user.longitude],
                          20,
                          units: :km
                        )
                        .where(runner_profiles: {
                          objective: current_user.runner_profile.objective
                        })

    # 2. Préparation des matches avec leurs scores
    matches_with_details = @base_matches.map do |user|
      # Cache les calculs de compatibilité
      compatibility = {
        pace_match: pace_compatibility(user),
        distance_match: distance_compatibility(user),
        availability_match: availability_compatibility(user)
      }

      {
        user: user.as_json(
          only: [:id, :first_name, :city, :department, :profile_image, :bio],
          include: {
            runner_profile: {
              only: [:actual_pace, :usual_distance, :availability, :objective]
            }
          }
        ),
        distance_km: current_user.distance_to_user(user).round(1),
        compatibility_details: compatibility,
        score: calculate_total_score(compatibility)
      }
    end

    render json: {
      matches: matches_with_details,
      total: matches_with_details.size
    }
  end

  def apply_filters
    distance_km = params.dig(:filters, :distance)&.to_i || 20

    @base_matches = User.includes(:runner_profile)
                        .where.not(id: current_user.id)
                        .where.not(latitude: nil, longitude: nil)
                        .near(
                          [current_user.latitude, current_user.longitude],
                          distance_km,
                          units: :km
                        )
                        .where(runner_profiles: {
                          objective: current_user.runner_profile.objective
                        })

    # Appliquer les filtres démographiques
    if params[:filters].present?
      @base_matches = @base_matches.where("age >= ?", params[:filters][:age_min]) if params[:filters][:age_min].present?
      @base_matches = @base_matches.where("age <= ?", params[:filters][:age_max]) if params[:filters][:age_max].present?
      @base_matches = @base_matches.where(gender: params[:filters][:gender]) if params[:filters][:gender].present?
    end

    # Calcul des scores et compatibilités
    matches_with_details = @base_matches.map do |user|
      compatibility = {
        pace_match: pace_compatibility(user),
        distance_match: distance_compatibility(user),
        availability_match: availability_compatibility(user)
      }

      {
        user: user.as_json(
          only: [:id, :first_name, :city, :department, :profile_image, :bio],
          include: {
            runner_profile: {
              only: [:actual_pace, :usual_distance, :availability, :objective]
            }
          }
        ),
        distance_km: current_user.distance_to_user(user).round(1),
        compatibility_details: compatibility,
        score: calculate_total_score(compatibility)
      }
    end

    # Filtrer par critères de compatibilité si demandé
    if params[:filters].present?
      matches_with_details = matches_with_details.select do |match|
        (params[:filter_pace] != 'true' || match[:compatibility_details][:pace_match] >= 10) &&
        (params[:filter_distance] != 'true' || match[:compatibility_details][:distance_match] >= 10) &&
        (params[:filter_availability] != 'true' || match[:compatibility_details][:availability_match] >= 10)
      end
    end

    render json: {
      matches: matches_with_details,
      total: matches_with_details.size
    }
  end

  private

  def calculate_total_score(compatibility_details)
    (
      compatibility_details[:pace_match] * 0.4 +
      compatibility_details[:distance_match] * 0.3 +
      compatibility_details[:availability_match] * 0.3
    ).round
  end

  def pace_compatibility(other_user)
    return 0 unless current_user.runner_profile&.actual_pace.present? &&
                    other_user.runner_profile&.actual_pace.present?

    my_pace = parse_pace(current_user.runner_profile.actual_pace)
    other_pace = parse_pace(other_user.runner_profile.actual_pace)

    return 0 if my_pace.nil? || other_pace.nil?

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
    return nil unless pace_string.present? && pace_string.include?(':')

    begin
      minutes, seconds = pace_string.split(':').map(&:to_i)
      minutes * 60 + seconds
    rescue
      nil
    end
  end
end
