class LeaderboardsController < ApplicationController
  def index
    @users = User.order(points: :desc).limit(100)
  end
end
