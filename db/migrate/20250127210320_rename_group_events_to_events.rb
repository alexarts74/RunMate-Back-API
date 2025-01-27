class RenameGroupEventsToEvents < ActiveRecord::Migration[7.0]
  def change
    # Renommer la table
    rename_table :group_events, :events

    # Supprimer la référence au running_group
    remove_reference :events, :running_group, foreign_key: true

    # Renommer certaines colonnes pour plus de clarté
    rename_column :events, :title, :name
    rename_column :events, :date, :start_date
    rename_column :events, :meeting_point, :location

    # Ajouter le niveau
    add_column :events, :level, :integer, default: 0
    add_index :events, :level
  end
end
