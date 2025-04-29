require 'rails_helper'

RSpec.describe BooksController, type: :controller do
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

    context 'when quiz already exists' do
      let!(:quiz) { create(:quiz, book: book) }

      it 'does not create a new quiz' do
        expect {
          post :take_quiz, params: { id: book.id }
        }.not_to change(Quiz, :count)
      end

      it 'redirects to the book show page' do
        post :take_quiz, params: { id: book.id }
        expect(response).to redirect_to(book_path(book))
      end
    end

    context 'when quiz does not exist' do
      let(:quiz) { instance_double(Quiz) }
      let(:quiz_generator_double) { instance_double(Quizzes::GeneratorService, generate_quiz: quiz) }

      before do
        allow(Quizzes::GeneratorService).to receive(:new).with(book).and_return(quiz_generator_double)
      end

      it 'generates a new quiz' do
        expect(quiz_generator_double).to receive(:generate_quiz)
        post :take_quiz, params: { id: book.id }
      end

      it 'redirects to the book show page' do
        post :take_quiz, params: { id: book.id }
        expect(response).to redirect_to(book_path(book))
      end
    end
  end
end
