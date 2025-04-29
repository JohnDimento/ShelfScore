class Book < ApplicationRecord
  has_many :quizzes, dependent: :destroy
  has_many :quiz_attempts, through: :quizzes

  validates :title, presence: true
  validates :author, presence: true

  def self.search(query)
    return all if query.blank?

    # Split the query into words
    terms = query.split

    # Build the conditions
    conditions = []
    values = {}

    terms.each_with_index do |term, index|
      conditions << "(title ILIKE :term#{index} OR author ILIKE :term#{index})"
      values["term#{index}".to_sym] = "%#{term}%"
    end

    where(conditions.join(' AND '), values)
  end

  # Check if a book is in a user's bookshelf (they passed a quiz with >= 70%)
  def in_bookshelf?(user)
    return false unless user

    quiz_attempts.exists?(
      user: user,
      score: 70..100
    )
  end

  # Get all books in a user's bookshelf
  def self.in_bookshelf(user)
    return none unless user

    joins(quizzes: :quiz_attempts)
      .where(quiz_attempts: { user: user, score: 70..100 })
      .distinct
  end
end
