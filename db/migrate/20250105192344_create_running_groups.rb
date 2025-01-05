class CreateRunningGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :running_groups do |t|
      t.string :name
      t.text :description
      t.integer :level
      t.integer :max_members
      t.string :location
      t.float :latitude
      t.float :longitude
      t.references :creator, foreign_key: { to_table: :users }
      t.integer :status, default: 0
      t.string :cover_image
      t.jsonb :weekly_schedule
      t.integer :members_count, default: 0

      t.timestamps
    end

    add_index :running_groups, :status
    add_index :running_groups, :level
  end
end
