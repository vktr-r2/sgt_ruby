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

  namespace :admin do
    get "/", to: "admin#index", as: :index
    get "/table/:table", to: "admin#table_data", as: :table_data
    post "/table/:table", to: "admin#create_record", as: :create_record
    put "/table/:table/:id", to: "admin#update_record", as: :update_record
    delete "/table/:table/:id", to: "admin#delete_record", as: :delete_record
  end

  namespace :api do
    namespace :tournaments do
      get "current/scores", to: "tournaments#current_scores"
      get "history", to: "tournaments#history"
      get ":id/results", to: "tournaments#show_results"
    end

    namespace :standings do
      get "season", to: "standings#season"
    end
  end

end
