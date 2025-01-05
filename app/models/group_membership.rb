class GroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :running_group, counter_cache: :members_count

  enum role: {
    member: 0,
    admin: 1
  }

  validates :user_id, uniqueness: { scope: :running_group_id, message: "est déjà membre de ce groupe" }

  after_create :check_group_status
  after_destroy :update_group_status

  private

  def check_group_status
    if running_group.members_count >= running_group.max_members
      running_group.update(status: :full)
    end
  end

  def update_group_status
    if running_group.full? && running_group.members_count < running_group.max_members
      running_group.update(status: :active)
    end
  end
end
