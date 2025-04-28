class Quiz < ApplicationRecord
  belongs_to :book
  has_many :questions, dependent: :destroy

  validates :title, presence: true
end
