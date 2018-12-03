Rails.application.routes.draw do

  root 'reservations#index'

  resources "reservations"
  
  
  get 'login/add_user'
  post 'login/add_user'
  get 'login/login'
  get 'login/logout'
  get 'login/edit_user'
  get 'login/update_user'
  get 'login/delete_user'
  get 'login/list_users'
  get 'login/change_password'
  get 'abrechnung/index'
  get 'abrechnung/jahresstatistik'
  get 'abrechnung/detailliste'
  get 'abrechnung/benutzer'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
