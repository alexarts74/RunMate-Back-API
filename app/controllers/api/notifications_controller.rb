class Api::NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:mark_as_read]

  def index
    @notifications = current_user.notifications.recent
    render json: @notifications
  end

  def mark_as_read
    if @notification.update(read: true)
      render json: @notification
    else
      render json: @notification.errors, status: :unprocessable_entity
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    head :ok
  end

  def test
    user = User.find(params[:user_id])

    NotificationService.send_push_notification(
      user,
      "Test de notification",
      "Ceci est un message de test !",
      { test: true }
    )

    render json: { message: "Notification de test envoyée" }
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
