# frozen_string_literal: true

class BooksController < ApplicationController
  before_action :authenticate_user!, only: [:bookshelf, :take_quiz]
  before_action :set_book, only: [:show, :take_quiz]

  def index
    @books = Book.all
  end

  def show
    @quiz = @book.quizzes.includes(:questions).order(created_at: :desc).first
    @can_attempt = @quiz ? QuizAttempt.can_attempt?(current_user, @quiz) : true
  end

  def bookshelf
    @books = Book.in_bookshelf(current_user)
  end

  def take_quiz
    Rails.logger.info "Starting take_quiz action"
    Rails.logger.info "Found book: #{@book.title}"

    if ENV['OPENAI_API_KEY'].blank?
      Rails.logger.error "OpenAI API key is missing"
      error_msg = "OpenAI API key is not configured. Please set the OPENAI_API_KEY environment variable."
      respond_to do |format|
        format.html { redirect_to book_path(@book), error: error_msg }
        format.json { render json: { error: error_msg }, status: :unprocessable_entity }
      end
      return
    end

    begin
      Rails.logger.info "Initializing Quiz Generator Service"
      generator = Quizzes::GeneratorService.new(@book)
      Rails.logger.info "Generating quiz"
      @quiz = generator.generate_quiz!
      Rails.logger.info "Quiz generated successfully with ID: #{@quiz.id}"

      respond_to do |format|
        format.html { redirect_to take_book_quiz_path(@book, @quiz) }
        format.json { render json: { quiz_id: @quiz.id, message: 'Quiz generated successfully' } }
      end
    rescue StandardError => e
      Rails.logger.error "Quiz generation failed: #{e.message}\n#{e.backtrace.join("\n")}"
      error_msg = "Failed to generate quiz questions. Please try again."
      respond_to do |format|
        format.html { redirect_to book_path(@book), error: error_msg }
        format.json { render json: { error: error_msg }, status: :unprocessable_entity }
      end
    end
  end

  def google_search
    service = Books::GoogleBooksService.new
    result = service.search(params[:query], max_results: 5)

    if result[:success?]
      render json: {
        books: result[:books].map do |book|
          {
            id: book.id,
            title: book.volume_info.title,
            author: book.volume_info.authors&.join(', ') || 'Unknown Author',
            description: book.volume_info.description,
            thumbnail: book.volume_info.image_links&.thumbnail
          }
        end
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def import_from_google
    service = Books::GoogleBooksService.new
    result = service.import_book(params[:google_books_id])

    if result[:success?]
      book = result[:book]

      # Generate a quiz for the imported book
      if ENV['OPENAI_API_KEY'].present?
        begin
          generator = Quizzes::GeneratorService.new(book)
          quiz = generator.generate_quiz!
          render json: {
            book: book,
            quiz: quiz,
            message: 'Book imported and quiz generated successfully'
          }
        rescue => e
          render json: {
            book: book,
            error: "Book imported but quiz generation failed: #{e.message}"
          }, status: :partial_content
        end
      else
        render json: {
          book: book,
          error: "Book imported but quiz generation skipped (OpenAI API key missing)"
        }, status: :partial_content
      end
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end
end
