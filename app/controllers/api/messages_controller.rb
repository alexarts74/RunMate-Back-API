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


    # Récupérer le dernier message pour chaque conversation
    last_messages = Message.direct_messages
                          .where("(sender_id = ? AND recipient_id IN (?)) OR (recipient_id = ? AND sender_id IN (?))",
                                current_user.id, conversation_ids,
                                current_user.id, conversation_ids)
                          .select("DISTINCT ON (LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id)) messages.*")
                          .order(Arel.sql("LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id), created_at DESC"))
                          .includes(:sender)
                          .index_by { |m| [m.sender_id, m.recipient_id].reject { |id| id == current_user.id }.first }


    conversations = conversation_ids.map do |user_id|
      last_message = last_messages[user_id]
      {
        user: users[user_id].as_json(only: [:id, :first_name, :profile_image, :expo_push_token]),
        unread_messages: unread_counts[user_id] || 0,
        last_message: last_message ? {
          id: last_message.id,
          content: last_message.content,
          created_at: last_message.created_at,
          sender: {
            id: last_message.sender.id,
            first_name: last_message.sender.first_name,
            profile_image: last_message.sender.profile_image
          }
        } : nil
      }
    end

    # Trier les conversations par date du dernier message
    conversations = conversations.sort_by { |c| c[:last_message]&.[](:created_at) || Time.at(0) }.reverse
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
    # Vérifie si l'utilisateur est membre du groupe
    unless @running_group.member?(current_user)
      return render json: { error: "Vous n'êtes pas membre de ce groupe" }, status: :forbidden
    end


    # Récupérer le dernier message du groupe
    last_message = Message.where(running_group_id: @running_group.id)
                          .where(message_type: 'group')
                          .includes(:sender)
                          .order(Arel.sql("created_at DESC"))
                          .first
    # Récupérer tous les messages du groupe
    messages = @running_group.messages
                            .group_messages
                            .includes(:sender)
                            .order(Arel.sql("created_at DESC"))
                            .limit(50)


    response_data = {
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
        is_member: true,
        last_message: last_message ? {
          id: last_message.id,
          content: last_message.content,
          created_at: last_message.created_at,
          sender: {
            id: last_message.sender.id,
            first_name: last_message.sender.first_name,
            profile_image: last_message.sender.profile_image
          }
        } : nil
      },
      messages: messages.map { |message| group_message_json(message) }
    }
    render json: response_data
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
      message_type: 'group',
      running_group_id: message.running_group_id,
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
