class RunnerProfile < ApplicationRecord
  belongs_to :user

  OBJECTIVES = [
    '5km_sous_25min',
    '10km_sous_50min',
    'premier_semi_marathon',
    'premier_marathon',
    'preparation_trail',
    'ameliorer_endurance',
    'perdre_du_poids',
    'course_reguliere'
  ].freeze

  validates :actual_pace, presence: true
  validates :usual_distance, presence: true
  validates :availability, presence: true
  validates :objective, inclusion: {
    in: OBJECTIVES,
    message: "n'est pas un objectif valide"
  }

  before_validation :standardize_objective

  private

  def standardize_objective
    return unless objective
    self.objective = objective.to_s
  end
end
