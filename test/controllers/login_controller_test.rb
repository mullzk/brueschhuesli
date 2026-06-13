require "test_helper"

class LoginControllerTest < ActionDispatch::IntegrationTest
  test "add user and then log in with it" do
    login_as_user
    get "/login/add_user"

    assert_response :success
    post "/login/add_user", params: { name: "NewUser", password: "Password" }

    assert_response :unprocessable_entity
    assert_equal "Benutzer konnte nicht erstellt werden", flash[:notice]
    post "/login/add_user", params: { user: { name: "ACB", email: "NewMail", password: "Password" } }

    assert_redirected_to controller: "login", action: "list_users"

    post session_path, params: { name: "ACB", password: "Password" }

    assert_redirected_to root_path
  end

  test "edit user" do
    login_as_user

    user = FactoryBot.create(:user, name: "newuser", email: "email@mail.com", password: "password")
    url = "/login/edit_user?id=#{user.id}"
    get url

    assert_response :success
  end

  test "update user" do
    login_as_user

    user = FactoryBot.create(:user, name: "newuser", email: "email@mail.com", password: "password")
    post "/login/update_user", params: { id: user.id, user: { name: "NewName", email: "NewMail", password: "NewPassword" } }

    assert_redirected_to controller: "login", action: "list_users"
    assert User.authenticate("NewName", "NewPassword")
  end

  test "delete user" do
    login_as_user

    user = FactoryBot.create(:user, name: "newuser", email: "email@mail.com", password: "password")
    post "/login/update_user", params: { id: user.id, user: { name: "NewName", email: "NewMail", password: "NewPassword" } }

    assert_redirected_to controller: "login", action: "list_users"
    assert User.authenticate("NewName", "NewPassword")
    url = "/login/delete_user?id=#{user.id}"
    post url

    assert_redirected_to controller: "login", action: "list_users"
    assert_not User.authenticate("NewName", "NewPassword")
  end

  test "deleting a user with reservations is rejected gracefully" do
    login_as_user
    user = FactoryBot.create(:user, name: "Owner", password: "password")
    FactoryBot.create(:reservation, user: user)
    assert_no_difference -> { User.count } do
      post "/login/delete_user?id=#{user.id}"
    end
    assert_redirected_to controller: "login", action: "list_users"
  end

  test "list users" do
    get "/login/list_users"

    assert_redirected_to new_session_path
    login_as_user

    get "/login/list_users"

    assert_response :success
  end

  test "change password" do
    user = FactoryBot.create(:user, name: "newuser", email: "email@mail.com", password: "123")

    assert User.authenticate(user.name, "123")
    post session_path, params: { name: user.name, password: user.password }

    assert_redirected_to root_path

    get "/login/change_password"

    assert_response :success
    post "/login/change_password", params: { id: user.id, old_password: "abc", user: { password: "456", password_confirmation: "456" } }

    assert_equal "Altes Passwort ist ungültig", flash[:notice]
    assert_response :unprocessable_entity
    post "/login/change_password", params: { id: user.id, old_password: "123", user: { password: "456", password_confirmation: "798" } }

    assert_response :unprocessable_entity
    assert User.authenticate(user.name, "123")
    post "/login/change_password", params: { id: user.id, old_password: "123", user: { password: "456", password_confirmation: "456" } }

    assert_equal "Passwort geändert", flash[:notice]
    assert_redirected_to controller: "login", action: "list_users"
    assert_not User.authenticate(user.name, "123")
    assert User.authenticate(user.name, "456")
  end
end
