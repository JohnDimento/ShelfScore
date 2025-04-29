class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_and_book
  before_action :check_attempt_eligibility, only: [:take]

  def create
    generator = QuizGenerator.new(@book)

    begin
      @quiz = generator.generate_quiz!
      session[:quiz_answers] = {}  # Initialize empty answers hash
      redirect_to take_book_quiz_path(@book, @quiz), notice: "Quiz created successfully!"
    rescue => e
      Rails.logger.error("Quiz creation failed: #{e.message}")
      redirect_to book_path(@book),
                  alert: "Failed to generate quiz questions. Please try again."
    end
  end

  def take
    @current_question = (params[:question] || 0).to_i
    @question_count = @quiz.questions.count

    # Save the answer from the last question if it exists
    if params[:answers].present? && params[:last_question].present?
      session[:quiz_answers] ||= {}
      question_id = @quiz.questions[params[:last_question].to_i].id.to_s
      session[:quiz_answers][question_id] = params[:answers][question_id]
    end

    render :take
  end

  def submit
    # Save the last answer if present
    if params[:answers].present? && params[:last_question].present?
      session[:quiz_answers] ||= {}
      question_id = @quiz.questions[params[:last_question].to_i].id.to_s
      session[:quiz_answers][question_id] = params[:answers][question_id]
    end

    # Calculate score
    @correct_answers = 0
    @total_questions = @quiz.questions.count
    @user_answers = session[:quiz_answers] || {}

    @results = @quiz.questions.map do |question|
      user_answer = @user_answers[question.id.to_s]
      is_correct = user_answer == question.correct_answer
      @correct_answers += 1 if is_correct

      {
        question: question,
        user_answer: user_answer,
        correct_answer: question.correct_answer,
        is_correct: is_correct
      }
    end

    @score_percentage = (@correct_answers.to_f / @total_questions * 100).round(2)

    # Record the quiz attempt
    @quiz_attempt = QuizAttempt.new(
      user: current_user,
      quiz: @quiz,
      score: @score_percentage,
      last_attempt_at: Time.current
    )

    if @quiz_attempt.save
      flash[:notice] = if @quiz_attempt.successful?
                        "Congratulations! You scored #{@score_percentage}% and this book will be added to your bookshelf!"
                      else
                        "You scored #{@score_percentage}%. You need at least 70% for this book to be added to your bookshelf. Try again next month!"
                      end
    else
      flash[:alert] = "Failed to record quiz attempt. #{@quiz_attempt.errors.full_messages.join(', ')}"
    end

    # Clear answers from session after storing them
    session.delete(:quiz_answers)

    render :results
  end

  private

  def set_quiz_and_book
    @quiz = Quiz.find(params[:id])
    @book = @quiz.book
  end

  def check_attempt_eligibility
    unless QuizAttempt.can_attempt?(current_user, @quiz)
      redirect_to book_path(@book),
                  alert: "You can only attempt this quiz once per month. Please try again next month."
    end
  end
end
