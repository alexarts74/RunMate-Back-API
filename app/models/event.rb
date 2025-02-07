class Event < ApplicationRecord
  DISTANCE_SQL = "3958.755864232 * 2 * ASIN(SQRT(POWER(SIN((:lat - events.latitude) * PI() / 180 / 2), 2) + COS(:lat * PI() / 180) * COS(events.latitude * PI() / 180) * POWER(SIN((:lng - events.longitude) * PI() / 180 / 2), 2)))"

  belongs_to :creator, class_name: 'User'
  has_many :event_participations, dependent: :destroy
  has_many :participants, through: :event_participations, source: :user

  validates :name, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :location, presence: true
  validates :max_participants, presence: true, numericality: { greater_than: 0 }
  validates :distance, presence: true, numericality: { greater_than: 0 }
  validates :pace, presence: true
  validates :level, presence: true

  enum level: {
    beginner: 0,
    intermediate: 1,
    advanced: 2,
    expert: 3
  }

  enum status: {
    upcoming: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3
  }

  geocoded_by :location
  after_validation :geocode, if: :location_changed?
  before_validation :set_initial_status, on: :create

  scope :upcoming, -> { where(status: :upcoming).where('start_date > ?', Time.current) }
  scope :past, -> { where(status: [:completed, :cancelled]) }
  scope :by_level, ->(level) { where(level: level) if level.present? }
  scope :near_location, ->(latitude, longitude, distance_km = 20) {
    near([latitude, longitude], distance_km)
  }

  def full?
    participants.count >= max_participants
  end

  def participant?(user)
    participants.include?(user)
  end

  def creator?(user)
    creator_id == user.id
  end

  def can_join?(user)
    !full? && !participant?(user) && upcoming?
  end

  def can_leave?(user)
    participant?(user) && upcoming?
  end

  def spots_left
    max_participants - participants.count
  end

  def update_status!
    if cancelled?
      return
    elsif Time.current > start_date + 2.hours
      completed!
    elsif Time.current >= start_date
      in_progress!
    end
  end

  private

  def set_initial_status
    self.status ||= :upcoming
  end
end
