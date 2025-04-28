class Quiz < ApplicationRecord
  belongs_to :book

  validates :title, presence: true
  validates :difficulty, presence: true, inclusion: { in: %w[Easy Medium Hard] }
end
