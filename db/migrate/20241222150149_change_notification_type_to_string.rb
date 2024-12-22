class ChangeNotificationTypeToString < ActiveRecord::Migration[7.0]
  def change
    change_column :notifications, :notification_type, :string
  end
end
