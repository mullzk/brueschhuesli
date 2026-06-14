# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication" do
    get users_path

    assert_redirected_to new_session_path
  end

  test "index lists users when authenticated" do
    login_as_user
    get users_path

    assert_response :success
  end

  test "new renders the form" do
    login_as_owner
    get new_user_path

    assert_response :success
  end

  test "create with invalid params re-renders the form" do
    login_as_owner
    post users_path, params: { user: { name: "NoMail", password: "Password" } }

    assert_response :unprocessable_entity
    assert_equal "Benutzer konnte nicht erstellt werden", flash[:notice]
  end

  test "create adds a user that can then log in" do
    login_as_owner
    post users_path, params: { user: { name: "ACB", email: "acb@example.com", password: "Password" } }

    assert_redirected_to users_path
    post session_path, params: { name: "ACB", password: "Password" }

    assert_redirected_to root_path
  end

  test "create persists miteigentuemer and telefon" do
    login_as_owner
    post users_path, params: { user: { name: "Owner", email: "owner@example.com", telefon: "079", miteigentuemer: "1", password: "Password" } }
    owner = User.find_by(name: "Owner")

    assert_predicate owner, :miteigentuemer
    assert_equal "079", owner.telefon
  end

  test "edit renders the form" do
    login_as_owner
    user = create(:user, name: "newuser", email: "email@mail.com", password: "password")
    get edit_user_path(user)

    assert_response :success
  end

  test "update changes the user" do
    login_as_owner
    user = create(:user, name: "newuser", email: "email@mail.com", password: "password")
    patch user_path(user), params: { user: { name: "NewName", email: "new@example.com", password: "NewPassword" } }

    assert_redirected_to users_path
    assert User.authenticate("NewName", "NewPassword")
  end

  test "update with blank password keeps the existing one" do
    login_as_owner
    user = create(:user, name: "newuser", email: "email@mail.com", password: "password")
    patch user_path(user), params: { user: { email: "changed@example.com", password: "", password_confirmation: "" } }

    assert_redirected_to users_path
    assert_equal "changed@example.com", user.reload.email
    assert User.authenticate("newuser", "password")
  end

  test "update a legacy user without a bcrypt digest and no new password" do
    login_as_owner
    user = create(:user, name: "Legacy", email: "legacy@example.com", password: "temporary")
    user.update_columns(password_digest: nil, salt: "s", hashed_password: User.legacy_hash("oldsecret", "s"))
    patch user_path(user), params: { user: { email: "newmail@example.com", password: "", password_confirmation: "" } }

    assert_redirected_to users_path
    assert_equal "newmail@example.com", user.reload.email
  end

  test "destroy removes the user" do
    login_as_owner
    user = create(:user, name: "newuser", email: "email@mail.com", password: "password")
    delete user_path(user)

    assert_redirected_to users_path
    assert_not User.authenticate("newuser", "password")
  end

  test "destroying a user with reservations is rejected gracefully" do
    login_as_owner
    user = create(:user, name: "Owner", password: "password")
    create(:reservation, user: user)

    assert_no_difference -> { User.count } do
      delete user_path(user)
    end
    assert_redirected_to users_path
  end
end
