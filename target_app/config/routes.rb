Rails.application.routes.draw do
  root 'top#index'

  resources :comments
  resources :posts
  resources :users
end
