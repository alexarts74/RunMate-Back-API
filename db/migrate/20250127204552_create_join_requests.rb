class CreateJoinRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :join_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :running_group, null: false, foreign_key: true
      t.text :message
      t.timestamps
    end

    add_index :join_requests, [:user_id, :running_group_id], unique: true
    add_column :running_groups, :privacy, :integer, default: 0
  end
end
