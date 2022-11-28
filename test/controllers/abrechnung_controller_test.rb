require 'test_helper'

class AbrechnungControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = FactoryBot.create(:user, name: 'User', email: 'test@mail.com', password: 'test1234')
    @reservation = FactoryBot.create(:reservation, user: @user, start: (DateTime.now - 3.days), finish: DateTime.now,
                                                   type_of_reservation: Reservation::KURZAUFENTHALT)
  end

  test 'should get index after login' do
    get abrechnung_index_url
    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_index_url
    assert_redirected_to controller: :abrechnung, action: :jahresstatistik
  end

  test 'should get jahresstatistik' do
    get abrechnung_jahresstatistik_url
    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_jahresstatistik_url
    assert_response :success
  end

  test 'should get detailliste' do
    get abrechnung_detailliste_url
    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_detailliste_url
    assert_response :success
  end

  test 'should get benutzer' do
    get abrechnung_benutzer_url params: { id: 1 }
    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_benutzer_url params: { id: @user.id }
    assert_response :success
  end

  test 'should get excel' do
    year = (DateTime.now - 3.days).year
    url = "/abrechnung/jahresstatistik.xls?year=#{year}"

    get url
    assert_redirected_to controller: :login, action: :login
    login_as_user

    get url
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
