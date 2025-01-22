class AddGroupToMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :messages, :running_group, foreign_key: true
    add_column :messages, :message_type, :string, default: 'direct'
    change_column_null :messages, :recipient_id, true
  end
end
