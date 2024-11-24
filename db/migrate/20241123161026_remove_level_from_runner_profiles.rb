class RemoveLevelFromRunnerProfiles < ActiveRecord::Migration[7.0]
  def change
    remove_column :runner_profiles, :level, :string
  end
end
