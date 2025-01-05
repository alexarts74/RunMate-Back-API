class CreateGroupEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :group_events do |t|
      t.string :title
      t.datetime :date
      t.string :meeting_point
      t.float :distance
      t.string :pace
      t.references :running_group, null: false, foreign_key: true
      t.references :creator, foreign_key: { to_table: :users }
      t.float :latitude
      t.float :longitude
      t.text :description
      t.integer :max_participants
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :group_events, :date
    add_index :group_events, :status
  end
end
