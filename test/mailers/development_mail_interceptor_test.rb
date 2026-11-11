# frozen_string_literal: true

require "test_helper"

# The interceptor is only registered in development, so these tests call it
# directly. SMTP credentials are stubbed.
class DevelopmentMailInterceptorTest < ActiveSupport::TestCase
  STUB_FROM = "from@example.com"

  test "every recipient is redirected to the configured from address" do
    stub_from(STUB_FROM)
    message = Mail.new(to: "max@example.com", cc: "cc@example.com", subject: "Hallo")
    DevelopmentMailInterceptor.delivering_email(message)

    assert_equal [ STUB_FROM ], message.to
    assert_nil message.cc
  end

  test "the original recipient is preserved in the subject" do
    stub_from(STUB_FROM)
    message = Mail.new(to: "max@example.com", subject: "Hallo")
    DevelopmentMailInterceptor.delivering_email(message)

    assert_includes message.subject, "max@example.com"
    assert_includes message.subject, "Hallo"
  end

  private

  def stub_from(address)
    smtp = Struct.new(:from, keyword_init: true).new(from: address)
    Rails.application.credentials.stubs(:smtp).returns(smtp)
  end
end
