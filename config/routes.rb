Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  root "chats#index"

  devise_for :users

  resources :chats, only: %i[index create show] do
    resources :messages, only: %i[create]
  end

  # Health check for deployment
  get "up" => "rails/health#show", as: :rails_health_check
end
