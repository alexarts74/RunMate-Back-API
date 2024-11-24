class Api::MatchesController < ApplicationController
  before_action :authenticate_user_from_token!

  def index
    @filters = {
      filter_pace: params[:filter_pace] == 'true',
      filter_distance: params[:filter_distance] == 'true',
      filter_availability: params[:filter_availability] == 'true'
    }

    Rails.logger.info "=== MATCHING DEBUG ==="
    Rails.logger.info "Filters: #{@filters.inspect}"

    base_matches = User.joins(:runner_profile)
                      .where.not(id: current_user.id)
                      .where(location: current_user.location)
                      .where(runner_profiles: {
                        objective: current_user.runner_profile.objective
                      })

    # Ici ce sont les utilisateurs qui ont le même objectif et sont dans la même ville que le current_user

    Rails.logger.info "Base matches count: #{base_matches.count}"

    matches = apply_filters(base_matches)

    matches_with_details = matches.map do |user|
      pace_score = pace_compatibility(user)
      distance_score = distance_compatibility(user)
      availability_score = availability_compatibility(user)

      Rails.logger.info "Match details for user #{user.id}:"
      Rails.logger.info "- Pace score: #{pace_score}"
      Rails.logger.info "- Distance score: #{distance_score}"
      Rails.logger.info "- Availability score: #{availability_score}"

      # Calcul du score et du pourcentage
      score = calculate_compatibility_score(user)
      percentage = ((score / 20.0) * 100).round  # Conversion du score en pourcentage

      {
        user: user.as_json(only: [:id, :name, :location, :profile_image, :bio],
                          include: {
                            runner_profile: {
                              only: [:actual_pace, :usual_distance, :availability, :objective]
                            }
                          }),
        score: score,
        percentage: percentage,
        compatibility_details: {
          pace_match: pace_score,
          distance_match: distance_score,
          availability_match: availability_score
        }
      }
    end

    Rails.logger.info "Final matches count: #{matches_with_details.size}"
    Rails.logger.info "Response data: #{matches_with_details.inspect}"
    Rails.logger.info "===================="

    render json: { matches: matches_with_details, total: matches_with_details.size }
  end

  private

  def apply_filters(matches)
    filtered_matches = matches

    if @filters[:filter_pace]
      filtered_matches = filtered_matches.select { |user| pace_compatibility(user) >= 10 }
    end

    if @filters[:filter_distance]
      filtered_matches = filtered_matches.select { |user| distance_compatibility(user) >= 10 }
    end

    if @filters[:filter_availability]
      filtered_matches = filtered_matches.select { |user| availability_compatibility(user) >= 10 }
    end

    filtered_matches
  end

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
