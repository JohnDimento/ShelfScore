require 'rails_helper'

RSpec.describe BooksController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    let!(:books) { create_list(:book, 3) }

    it 'assigns all books to @books' do
      get :index
      expect(assigns(:books)).to match_array(books)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #show' do
    let(:book) { create(:book) }
    let!(:quiz) { create(:quiz, book: book) }

    it 'assigns the requested book to @book' do
      get :show, params: { id: book.id }
      expect(assigns(:book)).to eq(book)
    end

    it 'assigns the book quiz to @quiz' do
      get :show, params: { id: book.id }
      expect(assigns(:quiz)).to eq(quiz)
    end

    it 'renders the show template' do
      get :show, params: { id: book.id }
      expect(response).to render_template(:show)
    end
  end

  describe 'POST #take_quiz' do
    let(:book) { create(:book) }

    context 'when OpenAI API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'redirects to book path with error' do
        post :take_quiz, params: { id: book.id }
        expect(response).to redirect_to(book_path(book))
        expect(flash[:error]).to include('OpenAI API key is not configured')
      end
    end

    context 'when OpenAI API key is present' do
      let(:quiz) { create(:quiz, book: book) }
      let(:generator_service) { instance_double(Quizzes::GeneratorService) }

      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        allow(Quizzes::GeneratorService).to receive(:new).with(book).and_return(generator_service)
      end

      context 'when quiz generation is successful' do
        before do
          allow(generator_service).to receive(:generate_quiz!).and_return(quiz)
        end

        it 'generates a new quiz and redirects to take quiz path' do
          post :take_quiz, params: { id: book.id }
          expect(response).to redirect_to(take_book_quiz_path(book, quiz))
        end
      end

      context 'when quiz generation fails' do
        before do
          allow(generator_service).to receive(:generate_quiz!).and_raise(StandardError.new('Quiz generation failed'))
        end

        it 'redirects to book path with error' do
          post :take_quiz, params: { id: book.id }
          expect(response).to redirect_to(book_path(book))
          expect(flash[:error]).to eq('Failed to generate quiz questions. Please try again.')
        end
      end
    end
  end
end
