class Question < ApplicationRecord
  belongs_to :quiz

  validates :content, presence: true
  validates :correct_answer, presence: true, inclusion: { in: %w[A B C D] }
  validates :options, presence: true
  validate :options_must_be_array_of_four

  private

  def options_must_be_array_of_four
    return if options.is_a?(Array) && options.size == 4

    errors.add(:options, "must be an array of exactly 4 options")
  end
end
