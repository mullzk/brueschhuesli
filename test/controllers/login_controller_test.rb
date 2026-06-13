require "test_helper"

class LoginControllerTest < ActionDispatch::IntegrationTest
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
    assert_redirected_to users_path
    assert_not User.authenticate(user.name, "123")
    assert User.authenticate(user.name, "456")
  end
end
