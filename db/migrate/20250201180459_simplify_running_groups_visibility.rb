class SimplifyRunningGroupsVisibility < ActiveRecord::Migration[7.0]
  def up
    # Mettre à jour tous les groupes existants en privé
    RunningGroup.update_all(visibility: 0)

    # Optionnel : supprimer l'index s'il existe
    remove_index :running_groups, :visibility if index_exists?(:running_groups, :visibility)
  end

  def down
    add_index :running_groups, :visibility
  end
end
