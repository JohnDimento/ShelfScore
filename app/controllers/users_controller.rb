class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_user, only: [:show, :edit, :update]

  def show
    @recent_books = Book.in_bookshelf(@user).limit(6)
    @quiz_attempts = @user.quiz_attempts.order(created_at: :desc).limit(5)
    @total_books = Book.in_bookshelf(@user).count
    @total_quizzes = @user.quiz_attempts.count
    @average_score = @user.quiz_attempts.average(:score)&.round(2) || 0
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :display_name,
      :bio,
      :avatar_url,
      :reading_goal,
      :theme_preference,
      privacy_settings: {}
    )
  end
end
