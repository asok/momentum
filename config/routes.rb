Rails.application.routes.draw do
  get "/api-docs", to: redirect("/scalar/")
  mount Rswag::Api::Engine => "/api-docs"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :public do
      namespace :v1 do
        resources :books, only: %i[index show create destroy] do
          post :borrow, on: :member
          post :return, on: :member
        end
      end
    end
  end
end
