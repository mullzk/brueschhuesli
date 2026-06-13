require "test_helper"

class AbrechnungControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = FactoryBot.create(:user, name: "User", email: "test@mail.com", password: "test1234")
    @reservation = FactoryBot.create(:reservation, user: @user, start: (DateTime.now-3.days), finish: DateTime.now, type_of_reservation: Reservation::KURZAUFENTHALT)
  end


  test "should get index after login" do
    get abrechnung_index_url

    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_index_url

    assert_redirected_to controller: :abrechnung, action: :jahresstatistik
  end

  test "should get jahresstatistik" do
    get abrechnung_jahresstatistik_url

    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_jahresstatistik_url

    assert_response :success
  end

  test "should get detailliste" do
    get abrechnung_detailliste_url

    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_detailliste_url

    assert_response :success
  end

  test "should get benutzer" do
    get abrechnung_benutzer_url params: { id: 1 }

    assert_redirected_to controller: :login, action: :login
    login_as_user

    get abrechnung_benutzer_url params: { id: @user.id }

    assert_response :success
  end


  test "should get excel" do
    year = (DateTime.now-(3.days)).year
    url = "/abrechnung/jahresstatistik.xls?year=#{year}"

    get url

    assert_redirected_to controller: :login, action: :login
    login_as_user

    get url

    assert_response :success
  end

  test "jahresstatistik xls sets the Excel download headers" do
    login_as_user
    get "/abrechnung/jahresstatistik.xls?year=#{@reservation.start.year}"

    assert_response :success
    assert_equal "application/vnd.ms-excel", response.media_type
    assert_match(/attachment; filename=/, response.headers["Content-Disposition"])
  end

  test "detailliste shows the classified type, not the stored column" do
    login_as_user
    get abrechnung_detailliste_url

    assert_response :success
    assert_select "td", text: Reservation::FERIENAUFENTHALT
    assert_not_includes response.body, Reservation::KURZAUFENTHALT
  end

  test "benutzer report shows the classified type, not the stored column" do
    login_as_user
    get abrechnung_benutzer_url(id: @user.id)

    assert_response :success
    assert_select "td", text: Reservation::FERIENAUFENTHALT
    assert_not_includes response.body, Reservation::KURZAUFENTHALT
  end

  # Verifies the Date.current injection in extract_year: with no params and time
  # frozen, jahresstatistik defaults to the current year (shown in the filename).
  test "jahresstatistik without params uses the current year" do
    travel_to Time.zone.local(2021, 7, 15) do
      login_as_user
      get "/abrechnung/jahresstatistik.xls"

      assert_response :success
      assert_match "2021", response.headers["Content-Disposition"]
    end
  end
end
