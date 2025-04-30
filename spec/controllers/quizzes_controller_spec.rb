require 'rails_helper'

RSpec.describe QuizzesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:book) { create(:book) }
  let(:quiz) { create(:quiz, book: book) }
  let!(:questions) { create_list(:question, 3, quiz: quiz) }

  before do
    sign_in user
  end

  describe 'POST #create' do
    let(:generator_service) { instance_double(Quizzes::GeneratorService) }

    before do
      allow(Quizzes::GeneratorService).to receive(:new).with(book).and_return(generator_service)
    end

    context 'when quiz generation is successful' do
      before do
        allow(generator_service).to receive(:generate_quiz!).and_return(quiz)
      end

      it 'creates a new quiz and redirects to take quiz path' do
        post :create, params: { book_id: book.id }
        expect(response).to redirect_to(take_book_quiz_path(book, quiz))
        expect(flash[:notice]).to eq('Quiz created successfully!')
        expect(session[:quiz_answers]).to eq({})
      end
    end

    context 'when quiz generation fails' do
      before do
        allow(generator_service).to receive(:generate_quiz!).and_raise(StandardError.new('Quiz generation failed'))
      end

      it 'redirects to book path with error' do
        post :create, params: { book_id: book.id }
        expect(response).to redirect_to(book_path(book))
        expect(flash[:alert]).to eq('Failed to generate quiz questions. Please try again.')
      end
    end
  end

  describe 'GET #take' do
    context 'when user can attempt the quiz' do
      before do
        allow(QuizAttempt).to receive(:can_attempt?).and_return(true)
      end

      it 'renders the take template' do
        get :take, params: { book_id: book.id, id: quiz.id }
        expect(response).to render_template(:take)
        expect(assigns(:current_question)).to eq(0)
        expect(assigns(:question_count)).to eq(3)
      end

      it 'saves the answer from the last question' do
        session[:quiz_answers] = {}
        get :take, params: {
          book_id: book.id,
          id: quiz.id,
          answers: { questions.first.id.to_s => 'A' },
          last_question: '0'
        }
        expect(session[:quiz_answers][questions.first.id.to_s]).to eq('A')
      end
    end

    context 'when user cannot attempt the quiz' do
      before do
        allow(QuizAttempt).to receive(:can_attempt?).and_return(false)
      end

      it 'redirects to book path with error' do
        get :take, params: { book_id: book.id, id: quiz.id }
        expect(response).to redirect_to(book_path(book))
        expect(flash[:alert]).to eq('You can only attempt this quiz once per month. Please try again next month.')
      end
    end
  end

  describe 'POST #submit' do
    let(:user_answers) do
      {
        questions[0].id.to_s => 'A',
        questions[1].id.to_s => 'B',
        questions[2].id.to_s => 'C'
      }
    end

    before do
      session[:quiz_answers] = user_answers
      questions[0].update!(correct_answer: 'A')
      questions[1].update!(correct_answer: 'B')
      questions[2].update!(correct_answer: 'D')
    end

    it 'calculates the score and creates a quiz attempt' do
      post :submit, params: { book_id: book.id, id: quiz.id }

      expect(assigns(:correct_answers)).to eq(2)
      expect(assigns(:total_questions)).to eq(3)
      expect(assigns(:score_percentage)).to eq(66.67)
      expect(assigns(:results)).to be_present
      expect(session[:quiz_answers]).to be_nil

      quiz_attempt = assigns(:quiz_attempt)
      expect(quiz_attempt).to be_persisted
      expect(quiz_attempt.score).to eq(66.67)
      expect(quiz_attempt.user).to eq(user)
      expect(quiz_attempt.quiz).to eq(quiz)

      expect(flash[:notice]).to include("You scored 66.67%")
      expect(response).to render_template(:results)
    end

    context 'when quiz attempt fails to save' do
      before do
        allow_any_instance_of(QuizAttempt).to receive(:save).and_return(false)
        allow_any_instance_of(QuizAttempt).to receive(:errors).and_return(
          double(full_messages: ['Error message'])
        )
      end

      it 'sets an error flash message' do
        post :submit, params: { book_id: book.id, id: quiz.id }
        expect(flash[:alert]).to eq('Failed to record quiz attempt. Error message')
      end
    end
  end
end
