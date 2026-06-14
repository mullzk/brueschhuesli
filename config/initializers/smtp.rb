# frozen_string_literal: true

# Maps the encrypted SMTP credentials onto ActionMailer. The values live in
# config/credentials.yml.enc under the `smtp` key. Without them (e.g. CI, which
# has no master key, or a local checkout before the block is filled in) the
# mapping is skipped so the app still boots; delivery then relies on the
# per-environment delivery_method.
if (smtp = Rails.application.credentials.smtp)
  ActionMailer::Base.smtp_settings = {
    address: smtp.address,
    port: smtp.port,
    user_name: smtp.user_name,
    password: smtp.password,
    authentication: :login,
    enable_starttls_auto: true,
    open_timeout: 5,
    read_timeout: 5
  }
end
