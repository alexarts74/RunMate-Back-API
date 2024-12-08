class Message < ApplicationRecord
    belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
    belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id'

    validates :content, presence: true

    scope :conversation_between, ->(user1_id, user2_id) do
        where("(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
              user1_id, user2_id, user2_id, user1_id)
        .order(created_at: :asc)
    end
end
