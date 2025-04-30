require 'rails_helper'

RSpec.describe QuizAnswersController, type: :controller do
  describe 'POST #create' do
    it 'stores the answer in the session' do
      post :create, params: { question_id: '123', answer: 'A' }

      expect(session[:quiz_answers]['123']).to eq('A')
      expect(response).to have_http_status(:ok)
    end

    it 'initializes the session hash if not present' do
      session[:quiz_answers] = nil

      post :create, params: { question_id: '123', answer: 'A' }

      expect(session[:quiz_answers]).to eq('123' => 'A')
      expect(response).to have_http_status(:ok)
    end
  end
end
