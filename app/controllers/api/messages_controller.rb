class Api::MessagesController < ApplicationController
  before_action :authenticate_user_from_token!

  # Obtenir toutes les conversations de l'utilisateur
  def index
    conversations = Message.where("sender_id = ? OR recipient_id = ?", current_user.id, current_user.id)
                          .select(:sender_id, :recipient_id)
                          .distinct
                          .map { |m| [m.sender_id, m.recipient_id].reject { |id| id == current_user.id }.first }
                          .uniq
                          .map do |user_id|
                            user = User.find(user_id)
                            unread_count = Message.where(sender_id: user_id, recipient_id: current_user.id, read: false).count
                            {
                              user: user.as_json(only: [:id, :first_name, :profile_image]),
                              unread_messages: unread_count,
                              last_message: Message.conversation_between(current_user.id, user_id).last
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
      NotificationService.create_notification(
        message.recipient,
        :new_message,
        "Nouveau message",
        "#{current_user.first_name} vous a envoyé un message",
        {
          message_id: message.id,
          sender_id: current_user.id,
          sender_name: current_user.first_name,
          sender_image: current_user.profile_image,
          conversation_id: message.recipient_id
        }
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
