class QuizzesController < ApplicationController
  def create
    @book = Book.find(params[:book_id])
    generator = QuizGenerator.new(@book)

    begin
      @quiz = generator.generate_quiz!
      redirect_to book_path(@book), notice: "Quiz created successfully!"
    rescue => e
      Rails.logger.error("Quiz creation failed: #{e.message}")
      redirect_to book_path(@book),
                  alert: "Failed to generate quiz questions. Please try again."
    end
  end
end
