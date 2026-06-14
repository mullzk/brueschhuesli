# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { runtime_from_header }
  layout "mailer"

  # Pure so all three cases (incl. development, which the mailer cannot reach in
  # the test environment) are directly unit-testable.
  def self.sender_display_name(development:, request_host:, production_host:)
    return "Brüschhüsli DEV" if development

    request_host == production_host ? "Brüschhüsli" : "Brüschhüsli INT"
  end

  private

  def runtime_from_header
    smtp = Rails.application.credentials.smtp
    return unless smtp

    name = self.class.sender_display_name(
      development: Rails.env.development?,
      request_host: Current.request_host,
      production_host: smtp.production_host
    )

    "#{name} <#{smtp.from}>"
  end
end
