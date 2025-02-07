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
    return render json: { error: 'Event complet' }, status: :unprocessable_entity if @event.full?
    return render json: { error: 'Vous participez déjà' }, status: :unprocessable_entity if @event.participant?(current_user)
    return render json: { error: 'Event non disponible' }, status: :unprocessable_entity unless @event.upcoming?

    participation = @event.event_participations.build(user: current_user)

    if participation.save
      render json: event_with_details(@event)
    else
      render json: { errors: participation.errors.full_messages }, status: :unprocessable_entity
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
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :name,
      :description,
      :start_date,
      :location,
      :distance,
      :pace,
      :level,
      :max_participants
    )
  end

  def ensure_creator
    unless @event.creator?(current_user)
      render json: { error: 'Non autorisé' }, status: :unauthorized
    end
  end

  def event_with_details(event)
    {
      id: event.id,
      name: event.name,
      description: event.description,
      start_date: event.start_date,
      location: event.location,
      distance: event.calculated_distance.to_f.round(2),
      pace: event.pace,
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
      is_creator: event.creator_id == current_user.id,
      is_participant: event.participants.map(&:id).include?(current_user.id),
      can_join: !event.participants.map(&:id).include?(current_user.id) && event.participants.size < event.max_participants,
      can_leave: event.participants.map(&:id).include?(current_user.id)
    }
  end
end
