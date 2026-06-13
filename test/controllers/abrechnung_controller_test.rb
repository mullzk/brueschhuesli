# frozen_string_literal: true

require "test_helper"

class AbrechnungControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = FactoryBot.create(:user, name: "User", email: "test@mail.com", password: "test1234")
    @reservation = FactoryBot.create(:reservation, user: @user, start: (DateTime.now - 3.days), finish: DateTime.now, type_of_reservation: Reservation::KURZAUFENTHALT)
  end

  def worksheet_xml(xlsx_body)
    Zip::InputStream.open(StringIO.new(xlsx_body)) do |io|
      while (entry = io.get_next_entry)
        return io.read if entry.name == "xl/worksheets/sheet1.xml"
      end
    end
  end

  test "should get index after login" do
    get abrechnung_index_url

    assert_redirected_to new_session_path
    login_as_user

    get abrechnung_index_url

    assert_redirected_to controller: :abrechnung, action: :jahresstatistik
  end

  test "should get jahresstatistik" do
    get abrechnung_jahresstatistik_url

    assert_redirected_to new_session_path
    login_as_user

    get abrechnung_jahresstatistik_url

    assert_response :success
  end

  test "should get detailliste" do
    get abrechnung_detailliste_url

    assert_redirected_to new_session_path
    login_as_user

    get abrechnung_detailliste_url

    assert_response :success
  end

  test "should get benutzer" do
    get abrechnung_benutzer_url params: { id: 1 }

    assert_redirected_to new_session_path
    login_as_user

    get abrechnung_benutzer_url params: { id: @user.id }

    assert_response :success
  end

  test "should get excel" do
    year = (DateTime.now - (3.days)).year
    url = "/abrechnung/jahresstatistik.xlsx?year=#{year}"

    get url

    assert_redirected_to new_session_path
    login_as_user

    get url

    assert_response :success
  end

  test "jahresstatistik xlsx sets the Excel download headers and returns a real xlsx" do
    login_as_user
    get "/abrechnung/jahresstatistik.xlsx?year=#{@reservation.start.year}"

    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert_match(/attachment; filename=/, response.headers["Content-Disposition"])
    assert response.body.start_with?("PK"), "expected a zip-based .xlsx payload"
  end

  test "jahresstatistik xlsx writes the totals as live SUM formulas" do
    login_as_user
    get "/abrechnung/jahresstatistik.xlsx?year=#{@reservation.start.year}"

    assert_includes worksheet_xml(response.body), "<f>SUM("
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
      get "/abrechnung/jahresstatistik.xlsx"

      assert_response :success
      assert_match "2021", response.headers["Content-Disposition"]
    end
  end
end
