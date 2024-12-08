class RunnerProfile < ApplicationRecord
  belongs_to :user

  OBJECTIVES = {
    '5km_sous_25min': '5km sous 25min',
    '10km_sous_50min': '10km sous 50min',
    'premier_semi_marathon': 'Premier semi-marathon',
    'premier_marathon': 'Premier marathon',
    'preparation_trail': 'Préparation trail',
    'ameliorer_endurance': 'Améliorer son endurance',
    'perdre_du_poids': 'Perdre du poids',
    'course_reguliere': 'Course régulière'
  }.freeze

  validates :actual_pace, presence: true
  validates :usual_distance, presence: true
  validates :availability, presence: true
  validates :objective, inclusion: {
    in: OBJECTIVES.values,
    message: "n'est pas un objectif valide"
  }

  before_validation :standardize_objective

  private

  def standardize_objective
    return unless objective
    self.objective = OBJECTIVES[objective] || objective
  end
end
