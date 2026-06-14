# frozen_string_literal: true

Rails.application.routes.draw do
  root "reservations#index"
  get "reservations/index/" => "reservations#index"
  get "reservations/on_day/:date", controller: "reservations", action: "on_day"
  get "reservations/month/:date", controller: "reservations", action: "month"

  resources "reservations"

  resource :session, only: %i[new create destroy]
  # Keep the old login URL working for existing bookmarks.
  get "login/login", to: redirect("/session/new")

  resources :users, except: :show
  resource :password, only: %i[edit update]
  get "abrechnung/index"
  get "abrechnung/jahresstatistik"
  get "abrechnung/detailliste"
  get "abrechnung/benutzer"

  get "admin" => "admin#index", as: :admin
  post "admin/test_email" => "admin#test_email", as: :admin_test_email

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
