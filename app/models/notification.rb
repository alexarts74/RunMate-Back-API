class Notification < ApplicationRecord
  belongs_to :user

  enum notification_type: {
    new_match: 0,
    new_message: 1,
    match_accepted: 2,
    running_reminder: 3
  }

  validates :title, presence: true
  validates :body, presence: true
  validates :notification_type, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
end
