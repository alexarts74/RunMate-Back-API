require 'http'

class NotificationService
  NOTIFICATION_TYPES = {
    message: 'message',
    match: 'match',
    run_invitation: 'run_invitation'
  }.freeze

  def self.create_notification(user, type, title, body, data = {})
    return nil unless user

    begin
      # Vérifier que le type est valide
      unless NOTIFICATION_TYPES.values.include?(type)
        Rails.logger.error "Type de notification invalide: #{type}"
        return nil
      end

      # Enrichir les données
      notification_data = enrich_notification_data(type, data)

      # Créer la notification
      notification = user.notifications.create!(
        notification_type: type,
        title: title.to_s,
        body: body.to_s,
        data: notification_data
      )

      # Envoyer la notification push
      if user.expo_push_token.present?
        send_push_notification(user, title, body, notification_data)
      end

      notification
    rescue => e
      Rails.logger.error "Erreur création notification: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

  # Notification de message
  def self.send_message_notification(recipient, sender, message_content)
    Rails.logger.info "Envoi notification message: #{sender.first_name} -> #{recipient.first_name}"

    create_notification(
      recipient,
      'message',
      "Message de #{sender.first_name}",
      message_content.to_s.truncate(100),
      {
        sender_id: sender.id,
        message_preview: message_content.to_s,
        screen: 'Messages'
      }
    )
  end

  # Notification de match
  def self.send_match_notification(recipient, matched_user)
    Rails.logger.info "Envoi notification match: #{matched_user.first_name} -> #{recipient.first_name}"

    create_notification(
      recipient,
      'match',
      'Nouveau match !',
      "#{matched_user.first_name} partage vos objectifs de course !",
      {
        matched_user_id: matched_user.id,
        matched_user_name: matched_user.first_name,
        matched_user_image: matched_user.profile_image,
        screen: 'Matches',
        objective: matched_user.runner_profile&.objective
      }
    )
  end

  # Notification d'invitation à courir
  def self.send_run_invitation_notification(recipient, sender, run_details)
    Rails.logger.info "Envoi notification course: #{sender.first_name} -> #{recipient.first_name}"

    create_notification(
      recipient,
      'run_invitation',
      'Invitation à courir',
      "#{sender.first_name} vous invite à courir !",
      {
        sender_id: sender.id,
        sender_name: sender.first_name,
        sender_image: sender.profile_image,
        run_id: run_details.id,
        run_date: run_details.date,
        run_location: run_details.location,
        screen: 'RunInvitation'
      }
    )
  end

  def self.send_push_notification(user, title, body, data = {})
    return unless user.expo_push_token

    message = {
      to: user.expo_push_token,
      sound: 'default',
      title: title,
      body: body,
      data: data,
      ios: ios_config(data[:type]),
      android: android_config(data[:type])
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
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  private

  def self.enrich_notification_data(type, data)
    data.merge({
      type: type,
      timestamp: Time.current.to_i
    })
  end

  def self.ios_config(type)
    {
      sound: true,
      _displayInForeground: true,
      badge: 1
    }
  end

  def self.android_config(type)
    {
      sound: true,
      priority: 'high',
      sticky: false,
      channelId: type,
      vibrate: true
    }
  end
end
