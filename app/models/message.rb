class Message < ApplicationRecord
    belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
    belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id', optional: true
    belongs_to :running_group, optional: true


    validates :content, presence: true
    validates :message_type, inclusion: { in: ['direct', 'group'] }

    scope :conversation_between, ->(user1_id, user2_id) do
        where("(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
              user1_id, user2_id, user2_id, user1_id)
        .order(created_at: :asc)
    end

    scope :direct_messages, -> { where(message_type: 'direct') }
    scope :group_messages, -> { where(message_type: 'group') }
    scope :for_group, ->(group_id) { where(running_group_id: group_id, message_type: 'group') }

    attribute :message_type, :string, default: 'direct'
end
