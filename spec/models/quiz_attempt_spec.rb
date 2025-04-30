require 'rails_helper'

RSpec.describe QuizAttempt, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:quiz) }
  end

  describe 'validations' do
    it { should validate_presence_of(:score) }
    it { should validate_presence_of(:last_attempt_at) }
    it { should validate_numericality_of(:score).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:score).is_less_than_or_equal_to(100) }
  end

  describe '.can_attempt?' do
    let(:user) { create(:user) }
    let(:quiz) { create(:quiz) }

    context 'when user or quiz is nil' do
      it 'returns false when user is nil' do
        expect(described_class.can_attempt?(nil, quiz)).to be false
      end

      it 'returns false when quiz is nil' do
        expect(described_class.can_attempt?(user, nil)).to be false
      end
    end

    context 'when no attempts exist' do
      it 'returns true' do
        expect(described_class.can_attempt?(user, quiz)).to be true
      end
    end

    context 'when an attempt exists this month' do
      before do
        create(:quiz_attempt, user: user, quiz: quiz, last_attempt_at: Time.current)
      end

      it 'returns false' do
        expect(described_class.can_attempt?(user, quiz)).to be false
      end
    end

    context 'when an attempt exists from last month' do
      before do
        create(:quiz_attempt, user: user, quiz: quiz, last_attempt_at: 1.month.ago)
      end

      it 'returns true' do
        expect(described_class.can_attempt?(user, quiz)).to be true
      end
    end
  end

  describe '#successful?' do
    let(:quiz_attempt) { build(:quiz_attempt) }

    it 'returns true when score is >= 70' do
      quiz_attempt.score = 70
      expect(quiz_attempt).to be_successful
      quiz_attempt.score = 100
      expect(quiz_attempt).to be_successful
    end

    it 'returns false when score is < 70' do
      quiz_attempt.score = 69.9
      expect(quiz_attempt).not_to be_successful
      quiz_attempt.score = 0
      expect(quiz_attempt).not_to be_successful
    end
  end

  describe 'one_attempt_per_month validation' do
    let(:user) { create(:user) }
    let(:quiz) { create(:quiz) }
    let(:quiz_attempt) { build(:quiz_attempt, user: user, quiz: quiz) }

    context 'when an attempt already exists this month' do
      before do
        create(:quiz_attempt, user: user, quiz: quiz, last_attempt_at: Time.current)
      end

      it 'is invalid' do
        expect(quiz_attempt).not_to be_valid
        expect(quiz_attempt.errors[:base]).to include('You can only attempt a quiz once per month')
      end
    end

    context 'when no attempt exists this month' do
      it 'is valid' do
        expect(quiz_attempt).to be_valid
      end
    end

    context 'when an attempt exists for a different quiz' do
      before do
        other_quiz = create(:quiz)
        create(:quiz_attempt, user: user, quiz: other_quiz, last_attempt_at: Time.current)
      end

      it 'is valid' do
        expect(quiz_attempt).to be_valid
      end
    end
  end
end
