class GroupEvent < ApplicationRecord
  belongs_to :running_group
  belongs_to :creator, class_name: 'User'
  has_many :event_participations, dependent: :destroy
  has_many :participants, through: :event_participations, source: :user

  validates :title, presence: true
  validates :date, presence: true
  validates :meeting_point, presence: true
  validates :distance, presence: true, numericality: { greater_than: 0 }
  validates :pace, presence: true
  validates :max_participants, presence: true, numericality: { greater_than: 0 }

  enum status: {
    scheduled: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3
  }

  geocoded_by :meeting_point
  after_validation :geocode, if: :meeting_point_changed?

  scope :upcoming, -> { where('date > ?', Time.current).order(date: :asc) }
  scope :past, -> { where('date <= ?', Time.current).order(date: :desc) }

  def full?
    participants.count >= max_participants
  end

  def can_join?(user)
    !full? && !participants.include?(user) && date > Time.current
  end
end
