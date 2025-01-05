class EventParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :group_event

  validates :user_id, uniqueness: { scope: :group_event_id, message: "participe déjà à cet événement" }
  validate :event_not_full, on: :create

  private

  def event_not_full
    if group_event.full?
      errors.add(:base, "L'événement est complet")
    end
  end
end
