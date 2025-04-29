class QuizAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :quiz

  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :last_attempt_at, presence: true
  validate :one_attempt_per_month, on: :create

  # Class method to check if a user can attempt a quiz
  def self.can_attempt?(user, quiz)
    return false unless user && quiz

    # Check if there's an attempt this month
    !exists?(
      user: user,
      quiz: quiz,
      last_attempt_at: Time.current.beginning_of_month..Time.current.end_of_month
    )
  end

  # Check if the attempt was successful (score >= 70)
  def successful?
    score >= 70
  end

  private

  def one_attempt_per_month
    return unless user && quiz

    if QuizAttempt.exists?(
      user: user,
      quiz: quiz,
      last_attempt_at: Time.current.beginning_of_month..Time.current.end_of_month
    )
      errors.add(:base, 'You can only attempt a quiz once per month')
    end
  end
end
