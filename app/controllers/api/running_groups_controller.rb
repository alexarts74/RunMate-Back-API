class Api::RunningGroupsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_running_group, except: [:index, :create]

  def index
    puts "HELLLOOOOOOOOOOOOOO"
    @groups = RunningGroup.includes(:creator, :members)
                          .near([current_user.latitude, current_user.longitude], 20)
                          .where(status: :active)

    render json: {
      groups: @groups.map { |group| group_with_details(group) },
      total: @groups.size
    }
  end

  def show
    render json: group_with_details(@running_group)
  end

  def create
    @running_group = current_user.created_groups.build(running_group_params)

    if @running_group.save
      render json: group_with_details(@running_group), status: :created
    else
      render json: { errors: @running_group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def join
    return render json: { error: 'Groupe complet' }, status: :unprocessable_entity if @running_group.full?

    membership = @running_group.group_memberships.build(user: current_user)

    if membership.save
      render json: { message: 'Vous avez rejoint le groupe avec succès' }
    else
      render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def leave
    membership = @running_group.group_memberships.find_by(user: current_user)

    if membership&.destroy
      render json: { message: 'Vous avez quitté le groupe' }
    else
      render json: { error: 'Vous n\'êtes pas membre de ce groupe' }, status: :unprocessable_entity
    end
  end

  private

  def set_running_group
    @running_group = RunningGroup.find(params[:id])
  end

  def running_group_params
    params.require(:running_group).permit(
      :name, :description, :level, :max_members,
      :location, :cover_image, weekly_schedule: []
    )
  end

  def group_with_details(group)
    {
      id: group.id,
      name: group.name,
      description: group.description,
      level: group.level,
      location: group.location,
      members_count: group.members_count,
      max_members: group.max_members,
      cover_image: group.cover_image,
      weekly_schedule: group.weekly_schedule,
      distance_km: current_user.distance_to([group.latitude, group.longitude])&.round(1),
      creator: {
        id: group.creator.id,
        name: group.creator.first_name,
        profile_image: group.creator.profile_image
      },
      is_member: group.members.include?(current_user),
      is_admin: group.group_memberships.exists?(user: current_user, role: :admin),
      upcoming_events: group.group_events.upcoming.limit(3)
    }
  end
end
