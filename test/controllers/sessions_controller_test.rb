require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "a protected page redirects to the login form when unauthenticated" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "login with a blank password is rejected" do
    user = create(:user, name: "user", email: "email@mail.com", password: "password")
    post session_path, params: { name: user.name, password: "" }

    assert_response :unprocessable_entity
    assert_equal "Ungültige Benutzer/Passwort Kombination", flash[:notice]
  end

  test "login with a wrong password is rejected" do
    user = create(:user, name: "user", email: "email@mail.com", password: "password")
    post session_path, params: { name: user.name, password: "nope" }

    assert_response :unprocessable_entity
    assert_equal "Ungültige Benutzer/Passwort Kombination", flash[:notice]
  end

  test "login with correct credentials redirects to the calendar" do
    user = create(:user, name: "user", email: "email@mail.com", password: "password")
    post session_path, params: { name: user.name, password: "password" }

    assert_redirected_to root_path
  end

  test "logout ends the session" do
    login_as_user
    delete session_path

    assert_redirected_to new_session_path
    get root_path

    assert_redirected_to new_session_path
  end

  test "an expired session no longer authenticates" do
    user = login_as_user
    user.sessions.update_all(created_at: (Session::MAX_AGE + 1.day).ago)
    get root_path

    assert_redirected_to new_session_path
  end

  test "the old /login/login bookmark redirects to the new login page" do
    get "/login/login"

    assert_redirected_to "/session/new"
  end
end
