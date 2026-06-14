# frozen_string_literal: true

require "test_helper"

# The SMTP credentials are stubbed so tests never depend on real secret values.
class TestMailerTest < ActionMailer::TestCase
  STUB_FROM = "from@example.com"

  # --- From address / wiring -------------------------------------------------

  test "test_email is addressed to the recipient and from the configured address" do
    stub_smtp_credentials
    mail = TestMailer.test_email("ziel@example.com")

    assert_equal [ "ziel@example.com" ], mail.to
    assert_equal [ STUB_FROM ], mail.from
    assert_predicate mail.subject, :present?
  end

  test "the From header reflects the derived sender name" do
    stub_smtp_credentials(production_host: "prod.example")
    Current.request_host = "other.example"
    mail = TestMailer.test_email("ziel@example.com")

    assert_match "Brüschhüsli INT", mail[:from].value
  end

  # --- sender name derivation (pure, covers all three cases) ------------------

  test "sender name is Brüschhüsli DEV in development" do
    assert_equal "Brüschhüsli DEV",
                 ApplicationMailer.sender_display_name(development: true, request_host: "x", production_host: "prod.example")
  end

  test "sender name is Brüschhüsli on the production host" do
    assert_equal "Brüschhüsli",
                 ApplicationMailer.sender_display_name(development: false, request_host: "prod.example", production_host: "prod.example")
  end

  test "sender name is Brüschhüsli INT on any other host" do
    assert_equal "Brüschhüsli INT",
                 ApplicationMailer.sender_display_name(development: false, request_host: "other.example", production_host: "prod.example")
  end

  private

  def stub_smtp_credentials(production_host: "prod.example")
    smtp = Struct.new(:from, :production_host, keyword_init: true)
                 .new(from: STUB_FROM, production_host: production_host)
    Rails.application.credentials.stubs(:smtp).returns(smtp)
  end
end
