class RemovePaceFromEvents < ActiveRecord::Migration[7.0]
  def change
    remove_column :events, :pace, :string
  end
end
