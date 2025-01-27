class RunningGroup < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :group_events, dependent: :destroy
  has_many :messages, dependent: :destroy

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

  enum privacy: {
    private: 0,
    public: 1
  }, _default: :private

  has_many :join_requests, dependent: :destroy
  has_many :requesting_users, through: :join_requests, source: :user

  geocoded_by :location
  after_validation :geocode, if: :location_changed?
  after_create :add_creator_as_admin

  def full?
    members_count >= max_members
  end

  def member?(user)
    members.include?(user)
  end

  def request_to_join(user)
    return false if member?(user)
    join_requests.create(user: user)
  end

  def accept_request(user)
    request = join_requests.find_by(user: user)
    return false unless request

    ActiveRecord::Base.transaction do
      group_memberships.create!(user: user)
      request.destroy
      # Envoyer notification d'acceptation
      true
    end
  end

  def decline_request(user)
    request = join_requests.find_by(user: user)
    return false unless request

    request.destroy
    # Envoyer notification de refus
    true
  end

  private

  def add_creator_as_admin
    group_memberships.create(user: creator, role: :admin)
  end
end
