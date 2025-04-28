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
      @quiz = @book.quizzes.first || QuizGenerator.new(@book).generate_quiz

      if @quiz.questions.empty?
        flash[:error] = "Failed to generate quiz questions. Please try again."
      else
        flash[:notice] = "Quiz generated successfully!"
      end
    rescue StandardError => e
      flash[:error] = "An error occurred while generating the quiz: #{e.message}"
    end

    redirect_to book_path(@book)
  end
end
