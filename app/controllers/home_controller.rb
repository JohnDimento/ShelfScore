class HomeController < ApplicationController
  def index
  end

  def search
    @books = Book.search(params[:title], params[:author])
    render :search
  end
end
