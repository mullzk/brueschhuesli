require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = login_as_user(password: "oldpass")
  end

  test "edit renders" do
    get edit_password_path

    assert_response :success
  end

  test "a wrong old password is rejected" do
    patch password_path, params: { old_password: "wrong", user: { password: "newpass", password_confirmation: "newpass" } }

    assert_response :unprocessable_entity
    assert_equal "Altes Passwort ist ungültig", flash[:notice]
    assert User.authenticate(@user.name, "oldpass")
  end

  test "a mismatched confirmation is rejected" do
    patch password_path, params: { old_password: "oldpass", user: { password: "newpass", password_confirmation: "different" } }

    assert_response :unprocessable_entity
    assert User.authenticate(@user.name, "oldpass")
  end

  test "a valid change replaces the password" do
    patch password_path, params: { old_password: "oldpass", user: { password: "newpass", password_confirmation: "newpass" } }

    assert_redirected_to users_path
    assert_equal "Passwort geändert", flash[:notice]
    assert_not User.authenticate(@user.name, "oldpass")
    assert User.authenticate(@user.name, "newpass")
  end

  test "changing the password cannot change name or email" do
    patch password_path, params: { old_password: "oldpass", user: { name: "Hacker", email: "hacker@example.com", password: "newpass", password_confirmation: "newpass" } }
    @user.reload

    assert_equal "Session User", @user.name
    assert_not_equal "hacker@example.com", @user.email
  end

  test "changing the password logs out other sessions" do
    other = @user.sessions.create!(user_agent: "other device", ip_address: "1.2.3.4")
    patch password_path, params: { old_password: "oldpass", user: { password: "newpass", password_confirmation: "newpass" } }

    assert_not Session.exists?(other.id)
  end
end
