class AddCoverImageToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :cover_image, :string
  end
end
