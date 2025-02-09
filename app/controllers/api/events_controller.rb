class Api::EventsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_event, only: [:show, :update, :destroy, :join, :leave]
  before_action :ensure_creator, only: [:update, :destroy]

  def index
    lat = current_user.latitude
    lng = current_user.longitude

    distance_formula = <<-SQL
      (3958.755864232 * 2 * ASIN(SQRT(
        POWER(SIN((#{lat} - events.latitude) * PI() / 180 / 2), 2) +
        COS(#{lat} * PI() / 180) * COS(events.latitude * PI() / 180) *
        POWER(SIN((#{lng} - events.longitude) * PI() / 180 / 2), 2)
      ))) AS calculated_distance
    SQL

    @events = Event.select("events.*, #{distance_formula}")
                    .includes(:creator, :participants, :event_participations)
                    .upcoming
                    .where("start_date > ?", Time.current)
                    .where(<<-SQL)
                      events.latitude BETWEEN #{lat} - 0.2895635662217 AND #{lat} + 0.2895635662217
                      AND events.longitude BETWEEN #{lng} - 0.416202980215766 AND #{lng} + 0.416202980215766
                      AND (
                        3958.755864232 * 2 * ASIN(SQRT(
                          POWER(SIN((#{lat} - events.latitude) * PI() / 180 / 2), 2) +
                          COS(#{lat} * PI() / 180) * COS(events.latitude * PI() / 180) *
                          POWER(SIN((#{lng} - events.longitude) * PI() / 180 / 2), 2)
                        ))
                      ) <= 20
                    SQL
                    .order('calculated_distance ASC')

    @events = @events.by_level(params[:level]) if params[:level].present?

    render json: {
      events: @events.map { |event| event_with_details(event) },
      total: @events.size,
      debug: {
        total_events: Event.count,
        upcoming_events: Event.upcoming.count,
        filtered_events: @events.size
      }
    }
  end

  def show
    lat = current_user.latitude
    lng = current_user.longitude

    distance_formula = <<-SQL
      (3958.755864232 * 2 * ASIN(SQRT(
        POWER(SIN((#{lat} - events.latitude) * PI() / 180 / 2), 2) +
        COS(#{lat} * PI() / 180) * COS(events.latitude * PI() / 180) *
        POWER(SIN((#{lng} - events.longitude) * PI() / 180 / 2), 2)
      ))) AS calculated_distance
    SQL

    @event = Event.select("events.*, #{distance_formula}")
                  .includes(:creator, :participants)
                  .find(params[:id])

    render json: event_with_details(@event)
  end

  def create
    @event = current_user.created_events.build(event_params)

    if @event.save
      render json: event_with_details(@event), status: :created
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      render json: event_with_details(@event)
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @event.destroy
      render json: { message: 'Event supprimé avec succès' }
    else
      render json: { error: 'Impossible de supprimer cet event' }, status: :unprocessable_entity
    end
  end

  def join
    lat = current_user.latitude
    lng = current_user.longitude

    Rails.logger.info "=== JOIN EVENT DEBUG ==="
    Rails.logger.info "Event ID: #{@event.id}"
    Rails.logger.info "Current User ID: #{current_user.id}"

    # Vérifier si l'utilisateur participe déjà
    existing_participation = EventParticipation.find_by(
      event_id: @event.id,
      user_id: current_user.id
    )

    if existing_participation
      Rails.logger.info "User already participating"
      return render json: {
        status: "error",
        code: "already_participating",
        message: "Vous participez déjà à cet événement"
      }, status: :ok  # 200 au lieu de 422
    end

    # Vérifier si l'événement est plein
    if @event.full?
      Rails.logger.info "Event is full"
      return render json: {
        status: "error",
        code: "event_full",
        message: "L'événement est complet"
      }, status: :ok  # 200 au lieu de 422
    end

    # Créer la participation
    participation = EventParticipation.new(event: @event, user: current_user)

    if participation.save
      Rails.logger.info "Participation created successfully"

      distance_formula = <<-SQL
        (3958.755864232 * 2 * ASIN(SQRT(
          POWER(SIN((#{lat} - events.latitude) * PI() / 180 / 2), 2) +
          COS(#{lat} * PI() / 180) * COS(events.latitude * PI() / 180) *
          POWER(SIN((#{lng} - events.longitude) * PI() / 180 / 2), 2)
        ))) AS calculated_distance
      SQL

      @event = Event.select("events.*, #{distance_formula}")
                    .includes(:creator, :participants)
                    .find(@event.id)

      render json: {
        status: "success",
        message: "Vous avez rejoint l'événement avec succès",
        data: event_with_details(@event)
      }, status: :ok
    else
      Rails.logger.error "Participation creation failed"
      render json: {
        status: "error",
        code: "creation_failed",
        message: participation.errors.full_messages.join(", ")
      }, status: :ok
    end
  end

  def leave
    participation = @event.event_participations.find_by(user: current_user)

    if participation&.destroy
      render json: { message: 'Participation annulée' }
    else
      render json: { error: 'Vous ne participez pas à cet event' }, status: :unprocessable_entity
    end
  end

  def my_events
    @participating = Event.joins(:event_participations)
                         .where(event_participations: { user_id: current_user.id })
                         .includes(:creator, :participants)

    @created = current_user.created_events.includes(:creator, :participants)

    render json: {
      participating: @participating.map { |event| event_with_details(event) },
      created: @created.map { |event| event_with_details(event) }
    }
  end

  def upcoming
    @events = Event.upcoming
                   .near([current_user.latitude, current_user.longitude], 20)
                   .includes(:creator, :participants)
                   .limit(10)

    render json: {
      events: @events.map { |event| event_with_details(event) }
    }
  end

  private

  def set_event
    @event = Event.includes(:participants).find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :name,
      :description,
      :start_date,
      :location,
      :distance,
      :level,
      :max_participants,
      :cover_image,
      :latitude,
      :longitude,
      :status
    )
  end

  def ensure_creator
    unless @event.creator?(current_user)
      render json: { error: 'Non autorisé' }, status: :unauthorized
    end
  end

  def event_with_details(event)
    # Calculer la distance si les coordonnées sont disponibles
    distance = if event.respond_to?(:calculated_distance)
      event.calculated_distance.to_f.round(2)
    elsif event.latitude && event.longitude && current_user.latitude && current_user.longitude
      event.distance_to([current_user.latitude, current_user.longitude]).to_f.round(2)
    else
      nil
    end

    {
      id: event.id,
      name: event.name,
      description: event.description,
      start_date: event.start_date,
      location: event.location,
      distance: distance,
      level: event.level,
      status: event.status,
      latitude: event.latitude,
      longitude: event.longitude,
      participants_count: event.participants.size,
      max_participants: event.max_participants,
      spots_left: event.max_participants - event.participants.size,
      creator: {
        id: event.creator.id,
        name: event.creator.first_name,
        profile_image: event.creator.profile_image
      },
      participants: event.participants.map { |participant|
        {
          id: participant.id,
          name: participant.first_name,
          profile_image: participant.profile_image,
          is_creator: participant.id == event.creator_id
        }
      },
      cover_image: event.cover_image,
      is_creator: event.creator_id == current_user.id,
      is_participant: event.participants.map(&:id).include?(current_user.id),
      can_join: !event.participants.map(&:id).include?(current_user.id) && event.participants.size < event.max_participants,
      can_leave: event.participants.map(&:id).include?(current_user.id)
    }
  end
end
