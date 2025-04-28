class AddGoogleBooksFieldsToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :google_books_id, :string
    add_column :books, :isbn_13, :string
    add_column :books, :isbn_10, :string
    add_column :books, :page_count, :integer
    add_column :books, :categories, :string, array: true, default: []
    add_column :books, :average_rating, :decimal, precision: 3, scale: 2
    add_column :books, :ratings_count, :integer
    add_column :books, :thumbnail_url, :string
    add_column :books, :preview_link, :string

    add_index :books, :google_books_id, unique: true
    add_index :books, :isbn_13
    add_index :books, :isbn_10
  end
end
