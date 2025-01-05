class CreateEventParticipations < ActiveRecord::Migration[7.0]
  def change
    create_table :event_participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group_event, null: false, foreign_key: true

      t.timestamps
    end

    add_index :event_participations, [:user_id, :group_event_id], unique: true
  end
end
