class RunnerProfile < ApplicationRecord
  belongs_to :user

  OBJECTIVES = {
    '5km_sous_25min' => '5km_sous_25min',
    '5km sous 25min' => '5km_sous_25min',
    '10km_sous_50min' => '10km_sous_50min',
    '10km sous 50min' => '10km_sous_50min',
    'premier_semi_marathon' => 'premier_semi_marathon',
    'Premier semi-marathon' => 'premier_semi_marathon',
    'premier_marathon' => 'premier_marathon',
    'Premier marathon' => 'premier_marathon',
    'preparation_trail' => 'preparation_trail',
    'Préparation trail' => 'preparation_trail',
    'ameliorer_endurance' => 'ameliorer_endurance',
    'Améliorer son endurance' => 'ameliorer_endurance',
    'perdre_du_poids' => 'perdre_du_poids',
    'Perdre du poids' => 'perdre_du_poids',
    'course_reguliere' => 'course_reguliere',
    'Course régulière' => 'course_reguliere'
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
