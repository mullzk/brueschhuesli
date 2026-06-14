# frozen_string_literal: true

require "test_helper"

class ReservationBillingTest < ActiveSupport::TestCase
  def billing(type:, blocks: 0, days: 0, owner: false, exclusive: false)
    ReservationBilling.new(type: type, blocks: blocks, days: days,
                           owner: owner, exclusive: exclusive)
  end

  test "short and long stays bill 15 CHF per block" do
    assert_equal 105, billing(type: Reservation::KURZAUFENTHALT, blocks: 7).fee
    assert_equal 105, billing(type: Reservation::FERIENAUFENTHALT, blocks: 7).fee
  end

  test "big event bills a flat fee regardless of duration" do
    assert_equal 200, billing(type: Reservation::GROSSANLASS, blocks: 7).fee
  end

  test "external use bills 100 CHF per calendar day" do
    assert_equal 300, billing(type: Reservation::EXTERNE_NUTZUNG, days: 3).fee
  end

  test "co-owner gets the first 6 blocks free on non-exclusive stays" do
    assert_equal 1, billing(blocks: 7, owner: true, exclusive: false,
                            type: Reservation::KURZAUFENTHALT).paid_blocks
    assert_equal 0, billing(blocks: 6, owner: true, exclusive: false,
                            type: Reservation::KURZAUFENTHALT).paid_blocks
  end

  test "co-owner discount does not apply to exclusive stays" do
    assert_equal 7, billing(blocks: 7, owner: true, exclusive: true,
                            type: Reservation::KURZAUFENTHALT).paid_blocks
  end

  test "non co-owner pays for every block" do
    assert_equal 7, billing(blocks: 7, owner: false, exclusive: false,
                            type: Reservation::KURZAUFENTHALT).paid_blocks
  end
end
