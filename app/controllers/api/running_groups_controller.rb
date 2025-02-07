class Api::RunningGroupsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_running_group, except: [:index, :create]
  before_action :ensure_member, only: [:show, :update, :destroy, :members]

  def index
    @running_groups = RunningGroup.joins(:group_memberships)
                                .where(group_memberships: { user_id: current_user.id })

    response_data = @running_groups.map do |group|
      last_message = Message.where(running_group_id: group.id)
                          .where(message_type: 'group')
                          .includes(:sender)
                          .order(created_at: :desc)
                          .first

      group_data = group_with_details(group)
      group_data[:last_message] = last_message ? {
        id: last_message.id,
        content: last_message.content,
        created_at: last_message.created_at,
        sender: {
          id: last_message.sender.id,
          first_name: last_message.sender.first_name,
          profile_image: last_message.sender.profile_image
        }
      } : nil

      group_data
    end

    render json: response_data
  end

  def show
    if @running_group.members.include?(current_user)
      render json: group_with_details(@running_group)
    else
      render json: {
        id: @running_group.id,
        name: @running_group.name,
        description: @running_group.description,
        level: @running_group.level,
        location: @running_group.location,
        members_count: @running_group.members_count,
        is_member: false,
        can_join: @running_group.can_join?(current_user),
        has_pending_request: @running_group.join_requests.exists?(user: current_user, status: :pending)
      }
    end
  end

  def create
    @running_group = current_user.created_groups.build(running_group_params)

    if @running_group.save
      GroupMembership.create!(user: current_user, running_group: @running_group, role: :admin)
      render json: group_with_details(@running_group), status: :created
    else
      render json: { errors: @running_group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def request_to_join
    return render json: { error: 'Groupe complet' }, status: :unprocessable_entity if @running_group.full?

    join_request = @running_group.join_requests.build(user: current_user)

    if join_request.save
      render json: { message: 'Demande envoyée' }
    else
      render json: { errors: join_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def leave
    membership = @running_group.group_memberships.find_by(user: current_user)

    if membership
      if membership.admin? && @running_group.admins.count == 1
        render json: { error: "Vous ne pouvez pas quitter le groupe car vous êtes le seul administrateur" },
               status: :unprocessable_entity
      else
        membership.destroy
        render json: { message: "Vous avez quitté le groupe avec succès" }
      end
    else
      render json: { error: "Vous n'êtes pas membre de ce groupe" },
             status: :unprocessable_entity
    end
  end

  private

  def set_running_group
    @running_group = RunningGroup.find(params[:id])
  end

  def ensure_member
    unless @running_group.members.include?(current_user)
      render json: { error: 'Vous devez être membre du groupe pour voir ces informations' },
             status: :unauthorized
    end
  end

  def running_group_params
    params.require(:running_group).permit(:name, :description, :level, :max_members,
                                        :location, :weekly_schedule, :cover_image)
  end

  def group_with_details(group)
    {
      id: group.id,
      name: group.name,
      description: group.description,
      level: group.level,
      location: group.location,
      max_members: group.max_members,
      members_count: group.members_count,
      cover_image: group.cover_image,
      weekly_schedule: group.weekly_schedule,
      creator: {
        id: group.creator.id,
        name: group.creator.first_name,
        profile_image: group.creator.profile_image
      },
      members: group.members.map { |member| {
        id: member.id,
        name: member.first_name,
        profile_image: member.profile_image,
        is_admin: group.group_memberships.exists?(user: member, role: :admin)
      }},
      is_admin: group.admins.include?(current_user),
      is_creator: group.creator == current_user,
      is_member: true,
      pending_requests_count: group.pending_requests.count
    }
  end
end
