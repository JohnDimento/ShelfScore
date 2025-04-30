require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #search' do
    let!(:book1) { create(:book, title: 'The Great Gatsby', author: 'F. Scott Fitzgerald') }
    let!(:book2) { create(:book, title: 'To Kill a Mockingbird', author: 'Harper Lee') }

    context 'when searching by title' do
      it 'returns matching books' do
        get :search, params: { title: 'gatsby' }
        expect(assigns(:books)).to include(book1)
        expect(assigns(:books)).not_to include(book2)
        expect(response).to render_template('home/search/index')
      end
    end

    context 'when searching by author' do
      it 'returns matching books' do
        get :search, params: { author: 'fitzgerald' }
        expect(assigns(:books)).to include(book1)
        expect(assigns(:books)).not_to include(book2)
        expect(response).to render_template('home/search/index')
      end
    end

    context 'when searching by both title and author' do
      it 'returns books matching both criteria' do
        get :search, params: { title: 'gatsby', author: 'fitzgerald' }
        expect(assigns(:books)).to include(book1)
        expect(assigns(:books)).not_to include(book2)
        expect(response).to render_template('home/search/index')
      end
    end

    context 'when no search parameters are provided' do
      it 'returns all books' do
        get :search
        expect(assigns(:books)).to include(book1, book2)
        expect(response).to render_template('home/search/index')
      end
    end
  end
end
