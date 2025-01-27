class Api::EventsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_event, only: [:show, :update, :destroy, :join, :leave]
  before_action :ensure_creator, only: [:update, :destroy]

  def index
    @events = Event.includes(:creator, :participants)
                   .upcoming
                   .near([current_user.latitude, current_user.longitude], 20)

    @events = @events.by_level(params[:level]) if params[:level].present?

    render json: {
      events: @events.map { |event| event_with_details(event) },
      total: @events.size
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
      # Envoyer une notification au créateur
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
      :name, :description, :start_date, :location,
      :distance, :pace, :level, :max_participants
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
      distance: event.distance,
      pace: event.pace,
      level: event.level,
      status: event.status,
      latitude: event.latitude,
      longitude: event.longitude,
      participants_count: event.participants.count,
      max_participants: event.max_participants,
      spots_left: event.spots_left,
      creator: {
        id: event.creator.id,
        name: event.creator.first_name,
        profile_image: event.creator.profile_image
      },
      is_creator: event.creator?(current_user),
      is_participant: event.participant?(current_user),
      can_join: event.can_join?(current_user),
      can_leave: event.can_leave?(current_user)
    }
  end
end
