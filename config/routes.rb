Rails.application.routes.draw do
  root 'reservation#index'

  get 'reservation/index'
  get 'reservation/show_detail'
  get 'reservation/update'
  get 'reservation/new'
  get 'reservation/new_reservation_in_ajax'
  get 'reservation/destroy'
  get 'login/add_user'
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
