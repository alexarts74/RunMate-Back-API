class RunningPreference < ApplicationRecord
  belongs_to :user

  # A voir ce qu'il y a a mettre en validations

  validates :distance, presence: true
  # validates :pace, presence: true
  # validates :availability, presence: true
  validates :level, presence: true
  # validates :preferred_gender, presence: true
  # validates :age_range, presence: true
end
