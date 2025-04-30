require 'rails_helper'

RSpec.describe Quizzes::GeneratorService do
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

    describe '#generate_quiz' do
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

        it 'returns nil' do
          expect(generator.generate_quiz).to be_nil
        end
      end
    end

    describe '#generate_quiz!' do
      it 'creates a quiz for the book' do
        expect { generator.generate_quiz! }.to change(Quiz, :count).by(1)
      end

      it 'raises an error when OpenAI API fails' do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(OpenAI::Error)
        expect { generator.generate_quiz! }.to raise_error(/Failed to generate quiz/)
      end
    end

    describe '#call' do
      it 'returns a success result with quiz when successful' do
        result = generator.call
        expect(result[:success?]).to be true
        expect(result[:quiz]).to be_a(Quiz)
      end

      it 'returns a failure result when OpenAI fails' do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(OpenAI::Error)
        result = generator.call
        expect(result[:success?]).to be false
        expect(result[:error]).to include("No questions returned from OpenAI")
      end

      context 'when quiz is provided' do
        let(:existing_quiz) { create(:quiz, book: book) }

        it 'updates the existing quiz' do
          result = generator.call(existing_quiz)
          expect(result[:success?]).to be true
          expect(result[:quiz]).to eq(existing_quiz)
          expect(existing_quiz.questions).to be_present
        end
      end
    end
  end
end
