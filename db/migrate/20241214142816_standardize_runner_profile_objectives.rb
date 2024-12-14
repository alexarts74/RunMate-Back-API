class StandardizeRunnerProfileObjectives < ActiveRecord::Migration[7.0]
  def up
    RunnerProfile.find_each do |profile|
      case profile.objective
      when '5km sous 25min'
        profile.update_column(:objective, '5km_sous_25min')
      when '10km sous 50min'
        profile.update_column(:objective, '10km_sous_50min')
      when 'Premier semi-marathon'
        profile.update_column(:objective, 'premier_semi_marathon')
      when 'Premier marathon'
        profile.update_column(:objective, 'premier_marathon')
      when 'Préparation trail'
        profile.update_column(:objective, 'preparation_trail')
      when 'Améliorer son endurance'
        profile.update_column(:objective, 'ameliorer_endurance')
      when 'Perdre du poids'
        profile.update_column(:objective, 'perdre_du_poids')
      when 'Course régulière'
        profile.update_column(:objective, 'course_reguliere')
      end
    end
  end

  def down
    # Si besoin de revenir en arrière
  end
end
