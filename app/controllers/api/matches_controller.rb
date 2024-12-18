class Api::MatchesController < ApplicationController
  before_action :authenticate_user_from_token!

  def index
    paris_users = User.where(location: "Paris").joins(:runner_profile)
    puts "\nTous les profils à Paris:"
    paris_users.each do |user|
      puts "- User #{user.id}: objective=#{user.runner_profile.objective}"
    end
    # 1. Base matches (critères fondamentaux)
    @base_matches = User.joins(:runner_profile)
                        .where.not(id: current_user.id)
                        .where(location: current_user.location)
                        .where(runner_profiles: {
                          objective: current_user.runner_profile.objective
                        })

    # 2. Préparation des matches avec leurs scores (sans filtrage)
    matches_with_details = @base_matches.map do |user|
      {
        user: user.as_json(only: [:id, :first_name, :location, :profile_image, :bio],
                          include: {
                            runner_profile: {
                              only: [:actual_pace, :usual_distance, :availability, :objective]
                            }
                          }),
        compatibility_details: {
          pace_match: pace_compatibility(user),
          distance_match: distance_compatibility(user),
          availability_match: availability_compatibility(user)
        },
        score: calculate_total_score({
          pace_match: pace_compatibility(user),
          distance_match: distance_compatibility(user),
          availability_match: availability_compatibility(user)
        })
      }
    end

    render json: {
      matches: matches_with_details,
      total: matches_with_details.size
    }
  end

  # 2. Nouvel endpoint pour appliquer les filtres
  def apply_filters
    puts "\n==== DÉBUT APPLY_FILTERS ===="
    puts "Paramètres reçus: #{params.inspect}"

    # Utiliser la location du filtre si présente, sinon utiliser la location du profil
    location_filter = params.dig(:filters, :location) || current_user.location
    puts "Location utilisée: #{location_filter}"

    # Récupérer les matches de base UNIQUEMENT avec la location_filter
    @base_matches = User.joins(:runner_profile)
                        .where.not(id: current_user.id)
                        .where(location: location_filter)  # Une seule condition de location
                        .where(runner_profiles: {
                          objective: current_user.runner_profile.objective
                        })

    puts "\nMatches de base avec location #{location_filter}:"
    puts "Nombre: #{@base_matches.count}"

    # Appliquer les autres filtres (SANS refiltrer la location)
    if params[:filters].present?
      puts "\nApplication des filtres démographiques..."

      if params[:filters][:age_min].present?
        @base_matches = @base_matches.where("age >= ?", params[:filters][:age_min])
        puts "Après filtre age_min (#{params[:filters][:age_min]}): #{@base_matches.count} matches"
      end

      if params[:filters][:age_max].present?
        @base_matches = @base_matches.where("age <= ?", params[:filters][:age_max])
        puts "Après filtre age_max (#{params[:filters][:age_max]}): #{@base_matches.count} matches"
      end

      if params[:filters][:gender].present?
        @base_matches = @base_matches.where(gender: params[:filters][:gender])
        puts "Après filtre gender (#{params[:filters][:gender]}): #{@base_matches.count} matches"
      end
    end

    # Calcul des scores
    @matches_with_scores = @base_matches.map do |user|
      puts "Calcul des scores pour user #{user.id} (#{user.first_name} #{user.last_name})"
      {
        user: user.as_json(only: [:id, :first_name, :location, :profile_image, :bio],
                          include: {
                            runner_profile: {
                              only: [:actual_pace, :usual_distance, :availability, :objective]
                            }
                          }),
        compatibility_details: {
          pace_match: pace_compatibility(user),
          distance_match: distance_compatibility(user),
          availability_match: availability_compatibility(user)
        }
      }
    end

    puts "==== FIN APPLY_FILTERS ===="

    # Application des filtres
    @filtered_matches = @matches_with_scores.select do |match|
      passes_filters = true

      if params[:filter_pace] == 'true'
        passes_filters &= match[:compatibility_details][:pace_match] >= 10
      end

      if params[:filter_distance] == 'true'
        passes_filters &= match[:compatibility_details][:distance_match] >= 10
      end

      if params[:filter_availability] == 'true'
        passes_filters &= match[:compatibility_details][:availability_match] >= 10
      end

      passes_filters
    end

    # Ajout des scores finaux
    final_matches = @filtered_matches.map do |match|
      match.merge(
        score: calculate_total_score(match[:compatibility_details]),
        filters_matched: {
          pace: match[:compatibility_details][:pace_match] >= 10,
          distance: match[:compatibility_details][:distance_match] >= 10,
          availability: match[:compatibility_details][:availability_match] >= 10
        }
      )
    end

    render json: {
      matches: final_matches,
      total: final_matches.size,
      stats: {
        total_base_matches: @base_matches.size,
        filtered_matches: final_matches.size,
        filter_stats: {
          pace: count_matches_by_filter(:pace_match),
          distance: count_matches_by_filter(:distance_match),
          availability: count_matches_by_filter(:availability_match)
        }
      }
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

  def count_matches_by_filter(filter_type)
    @matches_with_scores.count { |m| m[:compatibility_details][filter_type] >= 10 }
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
