class AddObjectiveToRunnerProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :runner_profiles, :objective, :string
  end
end
