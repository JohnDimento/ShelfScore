class Book < ApplicationRecord
  has_many :quizzes, dependent: :destroy

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
end
