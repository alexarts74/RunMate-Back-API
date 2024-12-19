class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :body
      t.boolean :read
      t.integer :notification_type
      t.jsonb :data

      t.timestamps
    end

    add_index :notifications, :read
    add_index :notifications, :notification_type
  end
end
