class EventParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id }
  validate :event_not_full, on: :create

  private

  def event_not_full
    if event.full?
      errors.add(:base, "L'événement est complet")
    end
  end
end
