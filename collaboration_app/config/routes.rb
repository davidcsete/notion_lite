Rails.application.routes.draw do
  # WebSocket route for Action Cable
  mount ActionCable.server => '/cable'
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication API
      post '/auth/login', to: 'sessions#create'
      delete '/auth/logout', to: 'sessions#destroy'
      get '/auth/me', to: 'sessions#show'
      
      # User API
      resources :users, only: [:create, :show, :update] do
        collection do
          get :search
        end
      end
      
      # Notes API
      resources :notes do
        resources :collaborations, only: [:index, :create, :update, :destroy]
        resources :operations, only: [:index, :create]
      end
    end
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
