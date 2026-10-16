Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :books, only: %i[index show create destroy] do
    post :borrow, on: :member
    post :return, on: :member
  end
end
