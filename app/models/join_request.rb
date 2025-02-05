class JoinRequest < ApplicationRecord
  belongs_to :user
  belongs_to :running_group

  validates :user_id, uniqueness: { scope: :running_group_id }

  enum status: {
    pending: 0,
    accepted: 1,
    declined: 2
  }

  scope :pending, -> { where(status: :pending) }
end
