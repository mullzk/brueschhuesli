require 'test_helper'

class ReservationControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get '/'
    assert_redirected_to controller: :login, action: :login
    login_as_user
    get '/'
    assert_response :success
  end

  private

  def login_as_user
    @admin = FactoryBot.build(:user)
    @admin.name = 'user'
    @admin.email = 'email@mail.com'
    @admin.password = 'password'
    @admin.save
    post '/login/login', params: { name: @admin.name, password: @admin.password }
  end
end
