class QuizzesController < ApplicationController
  def create
    @book = Book.find(params[:book_id])
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
    @quiz = Quiz.find(params[:id])
    @book = @quiz.book
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
    @quiz = Quiz.find(params[:id])
    @book = @quiz.book

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

    # Clear answers from session after storing them
    session.delete(:quiz_answers)

    render :results
  end
end
