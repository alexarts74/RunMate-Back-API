class Api::MessagesController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_running_group, only: [:group_index, :create_group_message]

  # Obtenir toutes les conversations de l'utilisateur (messages directs)
  def index
    conversation_ids = Message.direct_messages
                            .includes(:sender, :recipient)
                            .where("sender_id = ? OR recipient_id = ?", current_user.id, current_user.id)
                            .select(:sender_id, :recipient_id)
                            .distinct
                            .map { |m| [m.sender_id, m.recipient_id].reject { |id| id == current_user.id }.first }
                            .uniq

    users = User.where(id: conversation_ids).index_by(&:id)
    unread_counts = Message.direct_messages
                          .where(sender_id: conversation_ids, recipient_id: current_user.id, read: false)
                          .group(:sender_id)
                          .count

    conversations = conversation_ids.map do |user_id|
      {
        user: users[user_id].as_json(only: [:id, :first_name, :profile_image]),
        unread_messages: unread_counts[user_id] || 0
      }
    end

    render json: conversations
  end

  # Obtenir les messages d'une conversation spécifique (messages directs)
  def show
    other_user = User.find(params[:id])
    messages = Message.direct_messages.conversation_between(current_user.id, other_user.id)

    messages.where(recipient_id: current_user.id, read: false).update_all(read: true)

    render json: {
      other_user: other_user.as_json(only: [:id, :first_name, :profile_image]),
      messages: messages.as_json(methods: :read)
    }
  end

  # Obtenir les messages d'un groupe
  def group_index
    unless @running_group.member?(current_user)
      return render json: { error: "Vous n'êtes pas membre de ce groupe" }, status: :forbidden
    end

    messages = @running_group.messages
                            .group_messages
                            .includes(:sender)
                            .order(created_at: :desc)

    render json: {
      group: {
        id: @running_group.id,
        name: @running_group.name,
        description: @running_group.description,
        members: @running_group.members.map { |member| {
          id: member.id,
          first_name: member.first_name,
          profile_image: member.profile_image,
          is_admin: @running_group.group_memberships.exists?(user: member, role: :admin)
        }},
        total_members: @running_group.members_count,
        is_member: true # Nous savons que c'est true car nous avons vérifié plus haut
      },
      messages: messages.map { |message| group_message_json(message) }
    }
  end

  # Créer un message direct
  def create
    if params[:running_group_id]
      @running_group = RunningGroup.find(params[:running_group_id])
      create_group_message
    else
      create_direct_message
    end
  end

  # Créer un message de groupe
  def create_group_message
    unless @running_group.member?(current_user)
      return render json: { error: "Vous n'êtes pas membre de ce groupe" }, status: :forbidden
    end

    message = current_user.sent_messages.build(
      content: message_params[:content],
      running_group: @running_group,
      message_type: 'group'
    )

    if message.save
      render json: group_message_json(message), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @message = Message.find(params[:id])
    if @message.update(message_params)
      render json: @message
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_running_group
    @running_group = RunningGroup.find(params[:running_group_id])
  end

  def message_params
    params.require(:message).permit(:content, :recipient_id, :message_type, :running_group_id)
  end

  def group_message_json(message)
    {
      id: message.id,
      content: message.content,
      created_at: message.created_at,
      sender: {
        id: message.sender.id,
        first_name: message.sender.first_name,
        profile_image: message.sender.profile_image
      }
    }
  end

  def create_direct_message
    message = current_user.sent_messages.build(message_params.merge(message_type: 'direct'))
    message.read = false

    if message.save
      render json: message, status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
