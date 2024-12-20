class Api::MessagesController < ApplicationController
  before_action :authenticate_user_from_token!

  # Obtenir toutes les conversations de l'utilisateur
  def index
  # Récupérer les IDs des conversations avec eager loading
  conversation_ids = Message.includes(:sender, :recipient)
                          .where("sender_id = ? OR recipient_id = ?", current_user.id, current_user.id)
                          .select(:sender_id, :recipient_id)
                          .distinct
                          .map { |m| [m.sender_id, m.recipient_id].reject { |id| id == current_user.id }.first }
                          .uniq

  # Charger tous les utilisateurs et messages non lus en une seule fois
  users = User.where(id: conversation_ids).index_by(&:id)
  unread_counts = Message.where(sender_id: conversation_ids, recipient_id: current_user.id, read: false)
                        .group(:sender_id)
                        .count
  last_messages = Message.where("(sender_id = ? AND recipient_id IN (?)) OR (sender_id IN (?) AND recipient_id = ?)",
                              current_user.id, conversation_ids,
                              conversation_ids, current_user.id)
                        .order(created_at: :desc)
                        .group_by { |m| [m.sender_id, m.recipient_id].reject { |id| id == current_user.id }.first }
                        .transform_values(&:first)

  conversations = conversation_ids.map do |user_id|
    {
      user: users[user_id].as_json(only: [:id, :first_name, :profile_image]),
      unread_messages: unread_counts[user_id] || 0,
      last_message: last_messages[user_id]
    }
  end

  render json: conversations
end

  # Obtenir les messages d'une conversation spécifique
  def show
    other_user = User.find(params[:id])
    messages = Message.conversation_between(current_user.id, other_user.id)

    # Marquer les messages reçus comme lus
    messages.where(recipient_id: current_user.id, read: false).update_all(read: true)

    render json: {
      other_user: other_user.as_json(only: [:id, :first_name, :profile_image]),
      messages: messages.as_json(methods: :read)
    }
  end

  # Créer un nouveau message
  def create
    message = current_user.sent_messages.build(message_params)
    message.read = false

    if message.save
      ::NotificationService.send_message_notification(
        message.recipient,
        message.sender,
        message.content
      )
      render json: message, status: :created
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

  def message_params
    params.require(:message).permit(:content, :recipient_id, :read)
  end
end
