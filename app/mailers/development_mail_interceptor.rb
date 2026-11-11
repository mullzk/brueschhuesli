# frozen_string_literal: true

# Registered only in development (config/initializers/dev_mail_interceptor.rb):
# redirects every outgoing mail to the configured from address so it lands in
# the real inbox, keeping the intended recipients visible in the subject.
class DevelopmentMailInterceptor
  def self.delivering_email(message)
    smtp = Rails.application.credentials.smtp
    return unless smtp

    recipients = Array(message.to) + Array(message.cc) + Array(message.bcc)
    message.subject = "[dev → #{recipients.join(', ')}] #{message.subject}"
    message.to = smtp.from
    message.cc = nil
    message.bcc = nil
  end
end
