# frozen_string_literal: true

Rails.application.routes.draw do
  root 'reservations#index'
  get 'reservations/index/' => 'reservations#index'
  get 'reservations/on_day/:date', controller: 'reservations', action: 'on_day'
  get 'reservations/month/:date', controller: 'reservations', action: 'month'

  resources 'reservations'

  get 'login/add_user'
  post 'login/add_user'
  get 'login/login'
  post 'login/login'
  get 'login/logout'
  get 'login/edit_user'
  post 'login/update_user'
  patch 'login/update_user'
  get 'login/delete_user'
  post 'login/delete_user'
  get 'login/list_users'
  get 'login/change_password'
  post 'login/change_password'
  get 'abrechnung/index'
  get 'abrechnung/jahresstatistik'
  get 'abrechnung/detailliste'
  get 'abrechnung/benutzer'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
