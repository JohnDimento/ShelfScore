class Book < ApplicationRecord
  has_many :quizzes, dependent: :destroy

  validates :title, presence: true
  validates :author, presence: true

  def self.search(title, author)
    books = all
    books = books.where("title ILIKE ?", "%#{title}%") if title.present?
    books = books.where("author ILIKE ?", "%#{author}%") if author.present?
    books
  end
end
