class Notification < ApplicationRecord
  belongs_to :user

  enum notification_type: {
    message: 'message',
    match: 'match',
    run_invitation: 'run_invitation'
  }, _prefix: true

  validates :title, presence: true
  validates :body, presence: true
  validates :notification_type, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
end
