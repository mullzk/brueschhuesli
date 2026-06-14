# frozen_string_literal: true

require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "an owner can open the admin page" do
    login_as_owner
    get "/admin"

    assert_response :success
  end

  test "a member is denied the admin page" do
    login_as_user
    get "/admin"

    assert_redirected_to root_path
  end

  test "the shared account is denied the admin page" do
    login_as_user(role: :shared_account)
    get "/admin"

    assert_redirected_to root_path
  end

  test "test_email delivers one mail to the given address and redirects" do
    login_as_owner
    stub_smtp_credentials

    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      post "/admin/test_email", params: { email: "ziel@example.com" }
    end
    assert_equal [ "ziel@example.com" ], ActionMailer::Base.deliveries.last.to
    assert_redirected_to "/admin"
  end

  test "a failed delivery reports the error instead of raising" do
    login_as_owner
    delivery = mock
    delivery.stubs(:deliver_now).raises(StandardError, "smtp down")
    TestMailer.stubs(:test_email).returns(delivery)

    post "/admin/test_email", params: { email: "ziel@example.com" }

    assert_redirected_to "/admin"
    assert_match "fehlgeschlagen", flash[:notice]
  end

  test "a member cannot trigger a test mail" do
    login_as_user

    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      post "/admin/test_email", params: { email: "ziel@example.com" }
    end
    assert_redirected_to root_path
  end

  test "the admin page is not linked from the home page" do
    login_as_owner
    get root_path

    assert_select "a[href=?]", "/admin", count: 0
  end

  private

  def stub_smtp_credentials
    smtp = Struct.new(:from, :production_host, keyword_init: true)
                 .new(from: "from@example.com", production_host: "prod.example")
    Rails.application.credentials.stubs(:smtp).returns(smtp)
  end
end
