class Api::GroupEventsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_running_group
  before_action :set_event, except: [:index, :create]
  before_action :ensure_member, except: [:index, :show]

  def index
    @events = @running_group.group_events.includes(:creator, :participants)

    render json: {
      events: @events.map { |event| event_with_details(event) },
      total: @events.size
    }
  end

  def show
    render json: event_with_details(@event)
  end

  def create
    @event = @running_group.group_events.build(event_params)
    @event.creator = current_user

    if @event.save
      render json: event_with_details(@event), status: :created
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def join
    return render json: { error: 'Événement complet' }, status: :unprocessable_entity if @event.full?

    participation = @event.event_participations.build(user: current_user)

    if participation.save
      render json: { message: 'Participation enregistrée' }
    else
      render json: { errors: participation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def leave
    participation = @event.event_participations.find_by(user: current_user)

    if participation&.destroy
      render json: { message: 'Participation annulée' }
    else
      render json: { error: 'Vous ne participez pas à cet événement' }, status: :unprocessable_entity
    end
  end

  private

  def set_running_group
    @running_group = RunningGroup.find(params[:running_group_id])
  end

  def set_event
    @event = @running_group.group_events.find(params[:id])
  end

  def ensure_member
    unless @running_group.members.include?(current_user)
      render json: { error: 'Vous devez être membre du groupe' }, status: :forbidden
    end
  end

  def event_params
    params.require(:group_event).permit(
      :title, :date, :meeting_point, :distance,
      :pace, :description, :max_participants
    )
  end

  def event_with_details(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      meeting_point: event.meeting_point,
      distance: event.distance,
      pace: event.pace,
      description: event.description,
      max_participants: event.max_participants,
      participants_count: event.participants.count,
      status: event.status,
      creator: {
        id: event.creator.id,
        name: event.creator.first_name,
        profile_image: event.creator.profile_image
      },
      is_participant: event.participants.include?(current_user),
      can_join: event.can_join?(current_user)
    }
  end
end
