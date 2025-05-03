class AddProfileFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :display_name, :string
    add_column :users, :bio, :text
    add_column :users, :avatar_url, :string
    add_column :users, :reading_goal, :integer
    add_column :users, :theme_preference, :string
    add_column :users, :privacy_settings, :jsonb
  end
end
