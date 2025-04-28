class QuizAnswersController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    session[:quiz_answers] ||= {}
    session[:quiz_answers][params[:question_id].to_s] = params[:answer]

    head :ok
  end
end
