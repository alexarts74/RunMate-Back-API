class CreateRunnerProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :runner_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :actual_pace
      t.integer :usual_distance
      t.string :availability
      t.string :level

      t.timestamps
    end
  end
end
