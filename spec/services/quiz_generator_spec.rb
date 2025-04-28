require 'rails_helper'

RSpec.describe QuizGenerator do
  describe '#generate_quiz', :vcr do
    let(:book) { create(:book, title: 'The Great Gatsby', author: 'F. Scott Fitzgerald') }
    let(:generator) { described_class.new(book) }

    let(:openai_response) do
      {
        'choices' => [{
          'message' => {
            'content' => [
              {
                'content' => 'Who is the narrator of The Great Gatsby?',
                'options' => ['Nick Carraway', 'Jay Gatsby', 'Tom Buchanan', 'Jordan Baker'],
                'correct_answer' => 'A'
              }
            ].to_json
          }
        }]
      }
    end

    before do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(openai_response)
    end

    it 'creates a quiz for the book' do
      expect { generator.generate_quiz }.to change(Quiz, :count).by(1)
    end

    it 'creates questions for the quiz' do
      quiz = generator.generate_quiz
      expect(quiz.questions).to be_present
    end

    it 'sets the correct quiz title' do
      quiz = generator.generate_quiz
      expect(quiz.title).to eq("Quiz for #{book.title}")
    end

    context 'when OpenAI API fails' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(OpenAI::Error)
      end

      it 'creates a quiz without questions' do
        quiz = generator.generate_quiz
        expect(quiz).to be_persisted
        expect(quiz.questions).to be_empty
      end
    end

    context 'when OpenAI response cannot be parsed' do
      let(:openai_response) do
        {
          'choices' => [{
            'message' => {
              'content' => 'Invalid JSON'
            }
          }]
        }
      end

      it 'creates a quiz without questions' do
        quiz = generator.generate_quiz
        expect(quiz).to be_persisted
        expect(quiz.questions).to be_empty
      end
    end
  end
end
