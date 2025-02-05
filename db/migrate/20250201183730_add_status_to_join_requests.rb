class AddStatusToJoinRequests < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:join_requests, :status)
      add_column :join_requests, :status, :integer, default: 0
      add_index :join_requests, :status
    end
  end

  def down
    if column_exists?(:join_requests, :status)
      remove_index :join_requests, :status
      remove_column :join_requests, :status
    end
  end
end
