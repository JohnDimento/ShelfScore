class LeaderboardController < ApplicationController
  def index
    @users = User.order(total_points: :desc).limit(100)
  end
end
