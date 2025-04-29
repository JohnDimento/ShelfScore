class BooksController < ApplicationController
  before_action :authenticate_user!, only: [:bookshelf, :take_quiz]

  def index
    @books = Book.all
  end

  def show
    @book = Book.find(params[:id])
    @quiz = @book.quizzes.includes(:questions).order(created_at: :desc).first
    @can_attempt = @quiz ? QuizAttempt.can_attempt?(current_user, @quiz) : true
  end

  def bookshelf
    @books = Book.in_bookshelf(current_user)
  end

  def take_quiz
    Rails.logger.info "Starting take_quiz action"
    @book = Book.find(params[:id])
    Rails.logger.info "Found book: #{@book.title}"

    if ENV['OPENAI_API_KEY'].blank?
      Rails.logger.error "OpenAI API key is missing"
      flash[:error] = "OpenAI API key is not configured. Please set the OPENAI_API_KEY environment variable."
      redirect_to book_path(@book) and return
    end

    begin
      Rails.logger.info "Initializing QuizGenerator"
      generator = QuizGenerator.new(@book)
      Rails.logger.info "Generating quiz"
      @quiz = generator.generate_quiz!
      Rails.logger.info "Quiz generated successfully, redirecting to take quiz page"
      redirect_to take_book_quiz_path(@book, @quiz)
    rescue StandardError => e
      Rails.logger.error "Quiz generation failed: #{e.message}\n#{e.backtrace.join("\n")}"
      flash[:error] = "Failed to generate quiz questions. Please try again."
      redirect_to book_path(@book)
    end
  end
end
