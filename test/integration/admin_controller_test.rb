# frozen_string_literal: true

require "test_helper"

# Spec for Vorhaben #2 (E-Mail-Infrastruktur), /admin area. Commented out until
# the AdminController and TestMailer exist; activate per Feinplanungs-Schritt.
class AdminControllerTest < ActionDispatch::IntegrationTest
  # test "an owner can open the admin page" do
  #   login_as_owner
  #   get "/admin"
  #
  #   assert_response :success
  # end

  # test "a member is denied the admin page" do
  #   login_as_user
  #   get "/admin"
  #
  #   assert_redirected_to root_path
  # end

  # test "the shared account is denied the admin page" do
  #   login_as_user(role: :shared_account)
  #   get "/admin"
  #
  #   assert_redirected_to root_path
  # end

  # test "test_email delivers one mail to the given address and redirects" do
  #   login_as_owner
  #
  #   assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
  #     post "/admin/test_email", params: { email: "ziel@example.com" }
  #   end
  #   assert_equal ["ziel@example.com"], ActionMailer::Base.deliveries.last.to
  #   assert_redirected_to "/admin"
  # end

  # test "a member cannot trigger a test mail" do
  #   login_as_user
  #
  #   assert_no_difference -> { ActionMailer::Base.deliveries.size } do
  #     post "/admin/test_email", params: { email: "ziel@example.com" }
  #   end
  #   assert_redirected_to root_path
  # end

  # test "the admin page is not linked from the home page" do
  #   login_as_owner
  #   get root_path
  #
  #   assert_select "a[href=?]", "/admin", count: 0
  # end
end
