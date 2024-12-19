require 'http'

class NotificationService
  def self.create_notification(user, type, title, body, data = {})
    # Créer la notification en base
    notification = user.notifications.create!(
      notification_type: type,
      title: title,
      body: body,
      data: data
    )

    # Envoyer la notification push si l'utilisateur a un token
    send_push_notification(user, title, body, data) if user.expo_push_token.present?

    notification
  end

  def self.send_push_notification(user, title, body, data = {})
    return unless user.expo_push_token

    message = {
      to: user.expo_push_token,
      sound: 'default',
      title: title,
      body: body,
      data: data
    }

    begin
      response = HTTP.post(
        'https://exp.host/--/api/v2/push/send',
        json: message,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      )

      Rails.logger.info "Notification envoyée: #{response.body}"
    rescue => e
      Rails.logger.error "Erreur d'envoi de notification: #{e.message}"
    end
  end
end
