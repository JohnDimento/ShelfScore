class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :quiz_attempts
  has_many :quizzes, through: :quiz_attempts
  has_many :books, through: :quizzes
end
