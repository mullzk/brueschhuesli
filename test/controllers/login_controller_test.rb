require "test_helper"

class LoginControllerTest < ActionDispatch::IntegrationTest
  test "login with no credentials" do
    get "/login/list_users"

    assert_redirected_to controller: :login, action: :login

    user = FactoryBot.create(:user, name: "user", email: "email@mail.com", password: "password")
    post "/login/login", params: { name: user.name, password: "" }

    assert_response :unprocessable_entity
    assert_equal "Ungültige Benutzer/Passwort Kombination", flash[:notice]
  end

  test "login with wrong credentials" do
    get "/login/list_users"

    assert_redirected_to controller: :login, action: :login

    user = FactoryBot.create(:user, name: "user", email: "email@mail.com", password: "password")
    post "/login/login", params: { name: user.name, password: user.name }

    assert_response :unprocessable_entity
    assert_equal "Ungültige Benutzer/Passwort Kombination", flash[:notice]
  end

  test "login with correct credentials" do
    get "/login/list_users"

    assert_redirected_to controller: :login, action: :login

    user = FactoryBot.create(:user, name: "user", email: "email@mail.com", password: "password")
    post "/login/login", params: { name: user.name, password: user.password }

    assert_redirected_to controller: "reservations", action: "index"
  end

  test "logout after successful login" do
    login_as_user

    assert_redirected_to controller: "reservations", action: "index"
    get "/login/logout"

    assert_redirected_to controller: :login, action: :login
    get "/login/list_users"

    assert_redirected_to controller: :login, action: :login
  end

  test "an expired session no longer authenticates" do
    user = login_as_user
    user.sessions.update_all(created_at: (Session::MAX_AGE + 1.day).ago)
    get "/login/list_users"

    assert_redirected_to controller: :login, action: :login
  end


  test "add user and then log in with it" do
    login_as_user
    get "/login/add_user"

    assert_response :success
    post "/login/add_user", params: { name: "NewUser", password: "Password" }

    assert_response :unprocessable_entity
    assert_equal "Benutzer konnte nicht erstellt werden", flash[:notice]
    post "/login/add_user", params: { user: { name: "ACB", email: "NewMail", password: "Password" } }

    assert_redirected_to controller: "login", action: "list_users"

    post "/login/login", params: { name: "ACB", password: "Password" }

    assert_redirected_to controller: "reservations", action: "index"
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

    assert_redirected_to controller: :login, action: :login
    login_as_user

    get "/login/list_users"

    assert_response :success
  end

  test "change password" do
    user = FactoryBot.create(:user, name: "newuser", email: "email@mail.com", password: "123")

    assert User.authenticate(user.name, "123")
    post "/login/login", params: { name: user.name, password: user.password }

    assert_redirected_to controller: "reservations", action: "index"

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
