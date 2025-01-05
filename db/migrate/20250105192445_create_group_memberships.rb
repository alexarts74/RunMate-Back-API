class CreateGroupMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :running_group, null: false, foreign_key: true
      t.integer :role, default: 0

      t.timestamps
    end

    add_index :group_memberships, [:user_id, :running_group_id], unique: true
  end
end
