require 'test_helper'

class ReservationControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get reservation_index_url
    assert_response :success
  end

  test "should get show_detail" do
    get reservation_show_detail_url
    assert_response :success
  end

  test "should get update" do
    get reservation_update_url
    assert_response :success
  end

  test "should get new" do
    get reservation_new_url
    assert_response :success
  end

  test "should get new_reservation_in_ajax" do
    get reservation_new_reservation_in_ajax_url
    assert_response :success
  end

  test "should get destroy" do
    get reservation_destroy_url
    assert_response :success
  end

end
