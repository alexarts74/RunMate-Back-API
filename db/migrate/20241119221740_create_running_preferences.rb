class CreateRunningPreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :running_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :pace
      t.integer :distance
      t.string :availability
      t.string :level
      t.string :preferred_gender
      t.json :age_range

      t.timestamps
    end
  end
end
