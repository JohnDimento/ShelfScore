class Quiz < ApplicationRecord
  belongs_to :book
  has_many :questions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy

  validates :title, presence: true
end
