class HomeController < ApplicationController
  def index
  end

  def search
    # Build the search query based on available parameters
    query = []
    query << params[:title] if params[:title].present?
    query << params[:author] if params[:author].present?

    @books = Book.includes(quizzes: :questions).search(query.join(' '))
    render :search
  end
end
