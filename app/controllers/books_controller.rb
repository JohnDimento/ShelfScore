class BooksController < ApplicationController
  def index
    @books = Book.all
  end

  def show
    @book = Book.find(params[:id])
    @quiz = @book.quizzes.includes(:questions).order(created_at: :desc).first
  end

  def take_quiz
    @book = Book.find(params[:id])

    if ENV['OPENAI_API_KEY'].blank?
      flash[:error] = "OpenAI API key is not configured. Please set the OPENAI_API_KEY environment variable."
      redirect_to book_path(@book) and return
    end

    begin
      generator = QuizGenerator.new(@book)
      @quiz = generator.generate_quiz!
      redirect_to take_book_quiz_path(@book, @quiz)
    rescue StandardError => e
      flash[:error] = "Failed to generate quiz questions. Please try again."
      redirect_to book_path(@book)
    end
  end
end
