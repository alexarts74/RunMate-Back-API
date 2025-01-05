class RunningGroup < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :group_events, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :level, presence: true
  validates :max_members, presence: true, numericality: { greater_than: 0 }
  validates :location, presence: true

  enum level: {
    beginner: 0,
    intermediate: 1,
    advanced: 2,
    expert: 3
  }

  enum status: {
    active: 0,
    full: 1,
    archived: 2
  }

  geocoded_by :location
  after_validation :geocode, if: :location_changed?
  after_create :add_creator_as_admin

  def full?
    members_count >= max_members
  end

  private

  def add_creator_as_admin
    group_memberships.create(user: creator, role: :admin)
  end
end
