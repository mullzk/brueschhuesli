# frozen_string_literal: true

require "application_system_test_case"

class AbrechnungTest < ApplicationSystemTestCase
  test "the year-end accounting lists a user's fee" do
    user = sign_in_as
    create(:reservation, user: user) # 2019-02-01, 4h short stay -> 15 CHF

    visit abrechnung_jahresstatistik_path(year: 2019)

    assert_link "Resident"
    assert_text "15.-"
  end

  test "the per-user billing detail renders the fee in HTML" do
    user = sign_in_as
    create(:reservation, user: user) # 2019-02-01, 4h short stay -> 15 CHF

    visit abrechnung_benutzer_path(id: user.id, year: 2019)

    assert_text Reservation::KURZAUFENTHALT
    assert_text "15.-"
  end
end
