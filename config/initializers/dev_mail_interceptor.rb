# frozen_string_literal: true

# Registered after initialization so the constant is autoloadable, and only in
# development so the redirect never happens elsewhere.
Rails.application.config.after_initialize do
  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
end
