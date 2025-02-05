class AddVisibilityToRunningGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :running_groups, :visibility, :integer, default: 0
    add_index :running_groups, :visibility
  end
end
