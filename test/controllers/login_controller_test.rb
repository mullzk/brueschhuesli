require 'test_helper'

class LoginControllerTest < ActionDispatch::IntegrationTest
  test "should get add_user" do
    get login_add_user_url
    assert_response :success
  end

  test "should get login" do
    get login_login_url
    assert_response :success
  end

  test "should get logout" do
    get login_logout_url
    assert_response :success
  end

  test "should get edit_user" do
    get login_edit_user_url
    assert_response :success
  end

  test "should get update_user" do
    get login_update_user_url
    assert_response :success
  end

  test "should get delete_user" do
    get login_delete_user_url
    assert_response :success
  end

  test "should get list_users" do
    get login_list_users_url
    assert_response :success
  end

  test "should get change_password" do
    get login_change_password_url
    assert_response :success
  end

end
