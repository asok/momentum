Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: :create
  resources :books, only: %i[index show create destroy] do
    post :borrow, on: :member
    post :return, on: :member
  end
end
