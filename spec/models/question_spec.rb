require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'associations' do
    it { should belong_to(:quiz) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:correct_answer) }
    it { should validate_presence_of(:options) }
    it { should validate_inclusion_of(:correct_answer).in_array(%w[A B C D]) }
  end

  describe 'options validation' do
    let(:quiz) { create(:quiz) }

    it 'is valid with exactly 4 options' do
      question = build(:question, quiz: quiz, options: ['A', 'B', 'C', 'D'])
      expect(question).to be_valid
    end

    it 'is invalid with less than 4 options' do
      question = build(:question, quiz: quiz, options: ['A', 'B', 'C'])
      expect(question).not_to be_valid
      expect(question.errors[:options]).to include('must be an array of exactly 4 options')
    end

    it 'is invalid with more than 4 options' do
      question = build(:question, quiz: quiz, options: ['A', 'B', 'C', 'D', 'E'])
      expect(question).not_to be_valid
      expect(question.errors[:options]).to include('must be an array of exactly 4 options')
    end
  end
end
