class AddReadToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :read, :boolean, default: false
    add_index :messages, :read
  end
end
