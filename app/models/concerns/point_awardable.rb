module PointAwardable
  extend ActiveSupport::Concern

  included do
    after_save :award_points, if: :successful?
  end

  private

  def award_points
    Rails.logger.info "Attempting to award points for quiz attempt #{id}"
    return unless successful? && quiz.book.pages.present?

    # Calculate points: 1 point per 10 pages, rounded
    points = (quiz.book.pages.to_f / 10).round
    Rails.logger.info "Awarding #{points} points to user #{user.id} for book with #{quiz.book.pages} pages"
    user.increment!(:points, points)
  end
end
