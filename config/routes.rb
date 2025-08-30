require "sidekiq/web"
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  
  # Sidekiq paths - only mount if Redis is available
  mount Sidekiq::Web => "/sidekiq" if ENV["REDIS_URL"].present?

  # API root endpoint
  root to: "home#index"

  namespace :draft do
    get "/", to: "draft#index", as: :index
    post "/submit", to: "draft#submit", as: :submit
  end

end
