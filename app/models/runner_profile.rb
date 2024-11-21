class RunnerProfile < ApplicationRecord
  belongs_to :user

  validates :actual_pace, presence: true
  validates :usual_distance, presence: true
  validates :availability, presence: true
  validates :level, presence: true
end
