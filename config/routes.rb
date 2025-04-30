Rails.application.routes.draw do
  resources :leaderboards, only: [:index]
  devise_for :users
  root 'home#index'

  resources :books do
    collection do
      get :bookshelf
      get :google_search
      post :import_from_google
    end

    member do
      post :take_quiz
    end

    resources :quizzes, only: [:create] do
      member do
        get :take
        post :submit
      end
    end
  end

  resources :quizzes, only: [:show]

  get 'search', to: 'home#search'

  post 'quiz_answers', to: 'quiz_answers#create'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
